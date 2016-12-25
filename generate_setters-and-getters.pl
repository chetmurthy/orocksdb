#!/usr/bin/perl

use strict;
use warnings;
use Carp::Assert;
use Data::Dumper;
use Getopt::Long;

our $rocks_install ;
our $verbose ;
our @skip ;
our $skip_to ;

GetOptions(
	   "verbose" => \$verbose,
	   "skip=s" => \@skip,
	   "skip-to=s" => \$skip_to,
	   "rocks-install=s", => \$rocks_install,
	  ) or die("Error in command-line arguments") ;

assert (!@ARGV, "no extra args are allowd") ;

assert (-f "$rocks_install/include/rocksdb/c.h", "no such rocksdb install $rocks_install");

our $cheader = "$rocks_install/include/rocksdb/c.h" ;

{
  if (0) {
    my $full = f_contents($cheader) ;
    load_externals(
		   'content' => $full,
		   'skip' => \@skip,
		   'parse_fully' => 1,
		  ) ;
    exit ;
  }

  while(<STDIN>) {
    unless ($_ =~ /^#/) {
      print $_ ; next ;
    }

    if ($_ =~ /^#BEGIN setters-and-getters/) {
      my @l;
      push(@l, $_) ;
      while(<STDIN>) {
	push(@l, $_) ;
	if ($_ =~ /^#END/) { last ;}
      }
      expand(@l) ;
    }
  }
}

our $name;
our $sprefix ;
our %overrides ;

sub expand {
  my $spat ;
  my $epat ;

  # NOTE WELL that these are LOCAL, so visible in EMITTERS
  local $main::name ;
  local $main::sprefix ;
  local %main::overrides ;
  my @skips = () ;
  my @add = ();

  foreach my $l (@_) {
    next if $l =~ /^#BEGIN/ ;
    next if $l =~ /^#END/ ;
    if ($l =~ /start-pattern\s+\"(.*)\"$/) {
      $spat = quotemeta($1) ;
    }
    elsif ($l =~ /end-pattern\s+\"(.*)\"$/) {
      $epat = quotemeta($1) ;
    }
    elsif ($l =~ /name\s+\"(.*)\"$/) {
      $name = $1 ;
    }
    elsif ($l =~ /setter-prefix\s+\"(.*)\"$/) {
      $sprefix = $1 ;
    }
    elsif ($l =~ /skip\s+(.*)$/) {
      my @l = split(/\s+/, $1) ;
      push(@skips, @l) ;
    }
    elsif ($l =~ /add\s+(.*)$/) {
      my @l = split(/\s+/, $1) ;
      push(@add, @l) ;
    }
    elsif ($l =~ /override\s+(\S+)\s+(.*)$/) {
      $overrides{$1} = $2 ;
    }
    else {
      die "unrecognized line in setters-and-getters stanza <<$l>>" ;
    }
  }

  assert (defined $spat, "no start-pattern") ;
  assert (defined $epat,  "no end-pattern") ;
  assert (defined $name, "no name") ;
  assert (defined $sprefix, "no setter-prefix") ;

  my %skips = () ;
  foreach my $s (@skips) { $skips{$s} = 1 } ;

  my %adds = () ;
  foreach my $s (@add) { $adds{$s} = 1 } ;

  my $txt = f_contents($cheader) ;
  unless ($txt =~ s,.*($spat.*$epat).*,$1,s) {
    die "no text matches $spat .... $epat\n" ;
  }
  my @ext = load_externals(
			   'content' => $txt,
			   'skip' => [],
			   'parse_fully'=> 0,
			  ) ;
  {
    my @allext = load_externals(
			   'content' => f_contents($cheader) ,
			   'skip' => [],
			   'parse_fully'=> 0,
			  ) ;
      foreach my $q (@allext) {
	if (exists $adds{ $q->[0] }) {
	  push(@ext, $q) ;
	}
      }
  }

  foreach my $p (@ext) {
    my ($fname, $txt0) = @{ $p } ;
    print commentwrap($txt0) ;

    next if exists $skips{$fname} ;
    emit_setter($fname, $txt0) ;
  }
}

sub emit_setter {
  my $fname = shift;
  my $txt0 = shift;

  print STDERR "$fname\n";

  die "bad function name $fname"
    unless $fname =~ m/${sprefix}(\S+)/ ;

  my $suffname = $1 ;

  my ($ignore, $rty, $argtys) = parse_external($txt0, 1) ;
  assert ($rty eq 'void', "setter must return void") ;

  print STDERR Dumper($suffname, $argtys) if $main::verbose;

  my @argtys = @{ $argtys } ;
  assert ($argtys[0] eq "rocksdb_${name}_t*") ;
  my $argtxt = "" ;
  if (exists $overrides{$fname}) {
    $argtxt = $overrides{$fname} ;
  }
  else {
    foreach my $a (@argtys[1..$#argtys]) {
      $argtxt .= " ".convert_arg($a) ;
    }
  }

  my $n = "";
  if (int(@argtys) != 2) {
    $n = int(@argtys) - 1 ;
  }

  print <<"EOF";
    let ${suffname} =
      create_setter$n "${suffname}" $argtxt
EOF
}

our %argmap = ();

sub convert_arg {
  my $a = shift;

  unless (int(keys %argmap)) {
    %argmap =
      (
       'size_t' => 'Views.int_to_size_t',
       'int' => 'int',
       'unsigned char' => 'Views.bool_to_uchar',
       'rocksdb_cache_t*' => 'Cache.t',
       'uint64_t' => 'Views.int_to_uint64_t',
       'double' => 'float',
       'unsigned int' => 'Views.int_to_uint_t',
       'int32_t' => 'Views.int_to_int32_t',
       'uint32_t' => 'Views.int_to_uint32_t',
       'rocksdb_block_based_table_options_t*' => 'BlockBasedTableOptions.t',
      ) ;
  }
  assert(exists $argmap{$a}, "type $a cannot be converted") ;
  return $argmap{$a} ;
}

sub commentwrap {
  my $txt = shift ;
  my @l = split(/\n/, $txt) ;

  my @ol ;
  foreach my $l (@l) {
    next unless $l =~ /\S/ ;
    chomp $l ;
    $l =~ s,\*\),\* \),g;
    $l = "    (* ".$l." *)\n" ;
    push(@ol, $l) ;
  }
  return join('', @ol) ;
}

sub load_externals {
  my %args = @_ ;
  my $content = $args{'content'} ;
  my @skip = @{ $args{'skip'} } ;

  my %skip = () ;
  foreach my $e (@skip) { $skip{$e} = 1 ; }

  my @ext = ();
  while ($content =~ s,extern ROCKSDB_LIBRARY_API[^;]+;,,) {
    my $txt0 = $& ;
    my ($fname, @rest) = parse_external($txt0, 0) ;
    push (@ext, [$fname, $txt0]) ;

    next if $skip_to && $skip_to ne $fname ;
    unless (exists $skip{$fname}) {
      parse_external($txt0, $args{'parse_fully'}) ;
    }
  }
  return @ext ;
}

sub parse_external {
  my $txt0 = shift;
  my $full = shift ;

  my $txt = $txt0 ;
  unless ($txt =~ s,extern ROCKSDB_LIBRARY_API\s+([^\(]+)\(,\(,i) {
    die "malformed external <<$txt0>>" ;
  }
  my $rty_fname = $1 ;
  unless ($rty_fname =~ m,^(\S.*\S)\s+(rocks\S+)$,) {
    die "malformed return-type/fname: <<$rty_fname>>" ;
  }
  my $rty = $1 ;
  my $fname = $2 ;

  return $fname if !$full ;

  print STDERR "$rty <- $fname\n" if $main::verbose;

  recognize_type($rty) ;

  unless ($txt =~ s,\((.*)\),,s) {
    die "malformed formals <<$txt0>>" ;
  }
  my $argtxt = $1 ;
  $argtxt =~ s,\n, ,gs ;
  my @args = split(/,/, $argtxt) ;
  my @clean_args = () ;
  foreach my $a (@args) {
    $a = cleanws($a) ;
    $a = strip_formal_name($a) ;
    recognize_type($a) ;
    push(@clean_args, $a) ;
  }
  return($fname, $rty, \@clean_args) ;
}

sub strip_formal_name {
  my $arg = shift;
  if ($arg =~ m,^(.*[^a-z0-9_])([a-z_][a-z0-9_]*)$,) {
    my $l = $1 ;
    my $r = $2 ;
    unless ($r eq 'char' || $r eq 'int') {
      return cleanws($l);
    }
  }

  return $arg ;
}

sub cleanws {
  my $a = shift;
  $a =~ s,^\s+,,;
  $a =~ s,\s+$,,;
  return $a;
}

sub f_contents {
  my $f = shift;
  open(F, "<$f") || die "cannot open $f for read" ;
  local $/; # enable localized slurp mode
  my $content = <F>;
  close(F) ;
  return $content ;
}
our %types = () ;

sub recognize_type {
  my $t = shift ;

  unless (int(keys %types)) {

    my @types = (qw(
		    rocksdb_t*
		    rocksdb_backup_engine_t*
		    rocksdb_backup_engine_info_t*
		    rocksdb_restore_options_t*
		    rocksdb_cache_t*
		    rocksdb_compactionfilter_t*
		    rocksdb_compactionfiltercontext_t*
		    rocksdb_compactionfilterfactory_t*
		    rocksdb_comparator_t*
		    rocksdb_env_t*
		    rocksdb_fifo_compaction_options_t*
		    rocksdb_filelock_t*
		    rocksdb_filterpolicy_t*
		    rocksdb_flushoptions_t*
		    rocksdb_iterator_t*
		    rocksdb_logger_t*
		    rocksdb_mergeoperator_t*
		    rocksdb_options_t* rocksdb_options_t**
		    rocksdb_block_based_table_options_t*
		    rocksdb_cuckoo_table_options_t*
		    rocksdb_randomfile_t*
		    rocksdb_readoptions_t*
		    rocksdb_seqfile_t*
		    rocksdb_slicetransform_t*
		    rocksdb_snapshot_t*
		    rocksdb_writablefile_t*
		    rocksdb_writebatch_t*
		    rocksdb_writeoptions_t*
		    rocksdb_universal_compaction_options_t*
		    rocksdb_livefiles_t*
		    rocksdb_column_family_handle_t* rocksdb_column_family_handle_t**
		  ),
		 'rocksdb_t *',
		 "unsigned char",
		 "void",
		 "void*",
		 "int",
		 "unsigned int",
		 "int*",
		 "int32_t",
		 "uint32_t",
		 "int64_t",
		 "uint64_t",
		 "uint64_t*",
		 "size_t",
		 "size_t*",
		 "size_t*",
		 "double",
		 "char*", "char**",
		 "char* const*",
		 "rocksdb_column_family_handle_t* const*",
		 "rocksdb_iterator_t**",
		);


    foreach my $t (@types) {
      $types{$t} = 1 ;
      $types{"const $t"} = 1 ;
    }
  }

  assert (exists $types{$t}, "unrecognized type $t") ;
}
