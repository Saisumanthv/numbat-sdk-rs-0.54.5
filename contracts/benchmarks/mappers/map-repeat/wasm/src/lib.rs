// Code generated by the dharitri-sc build system. DO NOT EDIT.

////////////////////////////////////////////////////
////////////////// AUTO-GENERATED //////////////////
////////////////////////////////////////////////////

// Init:                                 1
// Endpoints:                            6
// Async Callback (empty):               1
// Total number of exported functions:   8

#![no_std]

dharitri_sc_wasm_adapter::allocator!();
dharitri_sc_wasm_adapter::panic_handler!();

dharitri_sc_wasm_adapter::endpoints! {
    map_repeat
    (
        init => init
        add => add
        count => count
        remove => remove
        add_struct => add_struct
        count_struct => count_struct
        remove_struct => remove_struct
    )
}

dharitri_sc_wasm_adapter::async_callback_empty! {}
