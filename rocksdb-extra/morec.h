
#pragma once

#include "rocksdb/c.h"

#ifdef __cplusplus
extern "C" {
#endif

/* BEGIN Myrocks comparators */

extern ROCKSDB_LIBRARY_API void rocksdb_options_set_myrocks_comparator(rocksdb_options_t*);

extern ROCKSDB_LIBRARY_API void rocksdb_options_set_rev_myrocks_comparator(rocksdb_options_t*);

/* END Myrocks comparators */

#ifdef __cplusplus
}
#endif
