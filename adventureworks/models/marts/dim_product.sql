with stg_product as (
    select 
        productid,
        cast(name as varchar) as name,
        productnumber,
        color,
        class,
        try_cast(productsubcategoryid as bigint) as productsubcategoryid
    from {{ source('raw', 'product') }}
),

stg_product_subcategory as (
    select 
        productsubcategoryid,
        productcategoryid,
        cast(name as varchar) as name
    from {{ source('raw', 'productsubcategory') }}
),

stg_product_category as (
    select
        productcategoryid,
        name
    from {{ source('raw', 'productcategory') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['stg_product.productid']) }} as product_key,
    stg_product.productid,
    stg_product.name as product_name,
    stg_product.productnumber,
    stg_product.color,
    stg_product.class,
    stg_product_subcategory.name as product_subcategory_name,
    stg_product_category.name as product_category_name
from stg_product
left join stg_product_subcategory on stg_product.productsubcategoryid = stg_product_subcategory.productsubcategoryid
left join stg_product_category on stg_product_subcategory.productcategoryid = stg_product_category.productcategoryid
