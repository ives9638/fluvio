use proc_macro2::TokenStream;
use crate::{SmartModuleConfig, SmartModuleFn, SmartModuleKind};

mod filter;
mod map;
mod array_map;
mod filter_map;
mod aggregate;
mod join;

pub mod opt;

pub fn generate_smartmodule(config: &SmartModuleConfig, func: &SmartModuleFn) -> TokenStream {
    match config.kind {
        SmartModuleKind::Filter => {
            self::filter::generate_filter_smartmodule(func, config.has_params)
        }
        SmartModuleKind::Map => self::map::generate_map_smartmodule(func, config.has_params),
        SmartModuleKind::FilterMap => {
            self::filter_map::generate_filter_map_smartmodule(func, config.has_params)
        }
        SmartModuleKind::Aggregate => {
            self::aggregate::generate_aggregate_smartmodule(func, config.has_params)
        }
        SmartModuleKind::ArrayMap => {
            self::array_map::generate_array_map_smartmodule(func, config.has_params)
        }
        SmartModuleKind::Join => self::join::generate_join_smartmodule(func, config.has_params),
    }
}
