open Ctypes
open Foreign
open Rocks_common

module Cache =
  struct
    type nonrec t = t
    let t = t

    let get_pointer = get_pointer

    let create_no_gc =
      (* extern rocksdb_cache_t* rocksdb_cache_create_lru(size_t capacity); *)
      foreign
        "rocksdb_cache_create_lru"
        (Views.int_to_size_t @-> returning t)

    let destroy =
      (* extern void rocksdb_cache_destroy(rocksdb_cache_t* cache); *)
      make_destroy t "rocksdb_cache_destroy"

    let create capacity =
      let t = create_no_gc capacity in
      Gc.finalise destroy t;
      t

    let with_t capacity f =
      let t = create_no_gc capacity in
      finalize
        (fun () -> f t)
        (fun () -> destroy t)

    let create_setter property_name property_typ =
      foreign
        ("rocksdb_cache_" ^ property_name)
        (t @-> property_typ @-> returning void)

#BEGIN setters-and-getters
    start-pattern "/* Cache */"
    end-pattern "/* Env */"
    name "cache"
    setter-prefix "rocksdb_cache_"
    skip rocksdb_cache_create_lru rocksdb_cache_destroy
#END
  end

module BlockBasedTableOptions =
  struct
    include CreateConstructors(struct
                                  let name = "block_based_table_options"
                                  let constructor = "rocksdb_block_based_options_create"
                                  let destructor  = "rocksdb_block_based_options_destroy"
                                  let setter_prefix = "rocksdb_block_based_options_"
                                end)
    module IndexType =
      struct
        type t = int
        let binary_search = 0
        let hash_search = 1
      end

#BEGIN setters-and-getters
    start-pattern "/* Block based table options */"
    end-pattern "/* Cuckoo table options */"
    name "block_based_table_options"
    setter-prefix "rocksdb_block_based_options_"
    skip rocksdb_block_based_options_create rocksdb_block_based_options_destroy
    skip rocksdb_options_set_block_based_table_factory rocksdb_block_based_options_set_filter_policy
#END
  end

module CuckooTableOptions =
  struct
    include CreateConstructors(struct
                                  let name = "cuckoo_table_options"
                                  let constructor = "rocksdb_cuckoo_options_create"
                                  let destructor  = "rocksdb_cuckoo_options_destroy"
                                  let setter_prefix = "rocksdb_cuckoo_options_"
                                end)

#BEGIN setters-and-getters
    start-pattern "/* Cuckoo table options */"
    end-pattern "/* Options */"
    name "cuckoo_table_options"
    setter-prefix "rocksdb_cuckoo_options_"
    skip rocksdb_cuckoo_options_create rocksdb_cuckoo_options_destroy
    skip rocksdb_options_set_cuckoo_table_factory
#END
  end

module Options = struct
  (* extern rocksdb_options_t* rocksdb_options_create(); *)
  (* extern void rocksdb_options_destroy(rocksdb_options_t*\); *)
  module C = CreateConstructors_(struct let name = "options" end)
  include C

#BEGIN setters-and-getters
    start-pattern "/* Options */"
#ifdef ROCKS_VERSION_MYROCKS
    end-pattern "/* RateLimiter */"
#else
    end-pattern "/* Compaction Filter */"
#endif
    name "options"
    setter-prefix "rocksdb_options_"
    skip rocksdb_options_create rocksdb_options_destroy
    skip rocksdb_options_set_compaction_filter rocksdb_options_set_compaction_filter_factory
    skip rocksdb_options_set_comparator rocksdb_options_set_merge_operator
    skip rocksdb_options_set_compression_per_level rocksdb_options_set_env
    skip rocksdb_options_set_info_log
    skip rocksdb_options_set_prefix_extractor
    skip rocksdb_options_set_max_bytes_for_level_multiplier_additional
    skip rocksdb_options_set_db_log_dir rocksdb_options_set_wal_dir
    skip rocksdb_options_set_universal_compaction_options
    skip rocksdb_options_set_fifo_compaction_options
    skip rocksdb_options_statistics_get_string
    add rocksdb_options_set_block_based_table_factory
    override rocksdb_options_set_use_fsync Views.bool_to_int
    skip rocksdb_options_set_filter_deletes
    skip rocksdb_options_set_memtable_prefix_bloom_bits rocksdb_options_set_memtable_prefix_bloom_probes
    override rocksdb_options_set_filter_deletes Views.bool_to_uchar
#ifdef ROCKS_VERSION_MYROCKS
    skip rocksdb_options_set_ratelimiter
    add rocksdb_options_set_myrocks_comparator rocksdb_options_set_rev_myrocks_comparator
#endif
#END
end

module WriteOptions = struct
  module C = CreateConstructors_(struct let name = "writeoptions" end)
  include C

#BEGIN setters-and-getters
    start-pattern "/* Write options */"
    end-pattern "/* Flush options */"
    name "writeoptions"
    setter-prefix "rocksdb_writeoptions_"
    skip rocksdb_writeoptions_create rocksdb_writeoptions_destroy
    override rocksdb_writeoptions_disable_WAL Views.bool_to_int
#END
end

module ReadOptions = struct
  module C = CreateConstructors_(struct let name = "readoptions" end)
  include C

#BEGIN setters-and-getters
    start-pattern "/* Read options */"
    end-pattern "/* Write options */"
    name "readoptions"
    setter-prefix "rocksdb_readoptions_"
    skip rocksdb_readoptions_create rocksdb_readoptions_destroy
    skip rocksdb_readoptions_set_snapshot
    skip rocksdb_readoptions_set_iterate_upper_bound
#END
end

module FlushOptions = struct
  module C = CreateConstructors_(struct let name = "flushoptions" end)
  include C

#BEGIN setters-and-getters
    start-pattern "/* Flush options */"
    end-pattern "/* Cache */"
    name "flushoptions"
    setter-prefix "rocksdb_flushoptions_"
    skip rocksdb_flushoptions_create rocksdb_flushoptions_destroy
#END
end
