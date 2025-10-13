package types

darray_fields_e :: enum {
    DARRAY_CAPACITY,
    DARRAY_LENGTH,
    DARRAY_ELEM_SIZE,
    DARRAY_FIELD_LENGTH,
}

DArray :: struct ($T: typeid) {
    capacity: u64,
    length: u64,
    type: typeid,
    data: [^]T,
}