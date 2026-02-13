# SQL - Tutorial Práctico con AdventureWorks

Tutorial de SQL usando las tablas del proyecto. Ejecuta estos ejemplos en **AWS Athena Console**.

---

## 📊 Tablas Disponibles

### Tablas RAW (seeds):
- `product` - Productos
- `customer` - Clientes
- `person` - Personas
- `salesorderheader` - Encabezados de órdenes
- `salesorderdetail` - Detalles de órdenes
- `address` - Direcciones
- `productcategory` - Categorías de productos
- `productsubcategory` - Subcategorías

### Tablas MARTS (transformadas):
- `marts.dim_product` - Dimensión de productos
- `marts.dim_customer` - Dimensión de clientes
- `marts.fct_sales` - Hechos de ventas
- `marts.obt_sales` - One Big Table (todo en una)

---

## 1️⃣ SELECT - Seleccionar Columnas

**Concepto**: `SELECT` define qué columnas quieres ver.

```sql
-- Ver todas las columnas (usa * con cuidado, puede ser lento)
SELECT * 
FROM raw.product 
LIMIT 10;

-- Seleccionar columnas específicas (recomendado)
SELECT 
    productid,
    name,
    color,
    listprice
FROM raw.product
LIMIT 10;

-- Renombrar columnas con alias
SELECT 
    productid AS id_producto,
    name AS nombre_producto,
    listprice AS precio
FROM raw.product
LIMIT 10;

-- Cálculos en SELECT
SELECT 
    name,
    listprice,
    listprice * 0.90 AS precio_con_descuento,
    listprice * 1.19 AS precio_con_iva
FROM raw.product
LIMIT 10;
```

---

## 2️⃣ WHERE - Filtrar Filas

**Concepto**: `WHERE` filtra qué filas quieres ver.

```sql
-- Filtro simple
SELECT name, listprice
FROM raw.product
WHERE listprice > 1000
LIMIT 10;

-- Múltiples condiciones (AND)
SELECT name, color, listprice
FROM raw.product
WHERE listprice > 500 
  AND color = 'Black'
LIMIT 10;

-- Condiciones alternativas (OR)
SELECT name, color, listprice
FROM raw.product
WHERE color = 'Red' 
   OR color = 'Blue'
LIMIT 10;

-- Filtro con IN (lista de valores)
SELECT name, color
FROM raw.product
WHERE color IN ('Red', 'Blue', 'Black')
LIMIT 10;

-- Filtro con LIKE (patrones de texto)
SELECT name
FROM raw.product
WHERE name LIKE '%Bike%'
LIMIT 10;

-- Filtro con BETWEEN (rangos)
SELECT name, listprice
FROM raw.product
WHERE listprice BETWEEN 100 AND 500
LIMIT 10;

-- Filtro con IS NULL / IS NOT NULL
SELECT name, color
FROM raw.product
WHERE color IS NULL
LIMIT 10;
```

---

## 3️⃣ ORDER BY - Ordenar Resultados

**Concepto**: `ORDER BY` ordena los resultados.

```sql
-- Ordenar ascendente (de menor a mayor)
SELECT name, listprice
FROM raw.product
ORDER BY listprice ASC
LIMIT 10;

-- Ordenar descendente (de mayor a menor)
SELECT name, listprice
FROM raw.product
ORDER BY listprice DESC
LIMIT 10;

-- Ordenar por múltiples columnas
SELECT name, color, listprice
FROM raw.product
ORDER BY color ASC, listprice DESC
LIMIT 10;
```

---

## 4️⃣ GROUP BY - Agrupar y Agregar

**Concepto**: `GROUP BY` agrupa filas y aplica funciones de agregación.

### Funciones de agregación:
- `COUNT()` - Contar
- `SUM()` - Sumar
- `AVG()` - Promedio
- `MIN()` - Mínimo
- `MAX()` - Máximo

```sql
-- Contar productos por color
SELECT 
    color,
    COUNT(*) AS cantidad_productos
FROM raw.product
WHERE color IS NOT NULL
GROUP BY color
ORDER BY cantidad_productos DESC;

-- Precio promedio por color
SELECT 
    color,
    COUNT(*) AS total_productos,
    AVG(listprice) AS precio_promedio,
    MIN(listprice) AS precio_minimo,
    MAX(listprice) AS precio_maximo
FROM raw.product
WHERE color IS NOT NULL
GROUP BY color
ORDER BY precio_promedio DESC;

-- Total de ventas por orden
SELECT 
    salesorderid,
    COUNT(*) AS items_en_orden,
    SUM(orderqty) AS cantidad_total,
    SUM(linetotal) AS venta_total
FROM raw.salesorderdetail
GROUP BY salesorderid
ORDER BY venta_total DESC
LIMIT 10;
```

### HAVING - Filtrar después de agrupar

```sql
-- Solo colores con más de 10 productos
SELECT 
    color,
    COUNT(*) AS cantidad
FROM raw.product
WHERE color IS NOT NULL
GROUP BY color
HAVING COUNT(*) > 10
ORDER BY cantidad DESC;

-- Órdenes con más de $10,000 en ventas
SELECT 
    salesorderid,
    SUM(linetotal) AS venta_total
FROM raw.salesorderdetail
GROUP BY salesorderid
HAVING SUM(linetotal) > 10000
ORDER BY venta_total DESC
LIMIT 10;
```

---

## 5️⃣ JOINS - Unir Tablas

**Concepto**: `JOIN` combina datos de múltiples tablas.

### INNER JOIN - Solo registros que coinciden en ambas tablas

```sql
-- Productos con su categoría
SELECT 
    p.name AS producto,
    pc.name AS categoria
FROM raw.product p
INNER JOIN raw.productsubcategory ps 
    ON p.productsubcategoryid = ps.productsubcategoryid
INNER JOIN raw.productcategory pc 
    ON ps.productcategoryid = pc.productcategoryid
LIMIT 10;

-- Órdenes con detalles
SELECT 
    h.salesorderid,
    h.orderdate,
    d.productid,
    d.orderqty,
    d.unitprice,
    d.linetotal
FROM raw.salesorderheader h
INNER JOIN raw.salesorderdetail d 
    ON h.salesorderid = d.salesorderid
LIMIT 10;
```

### LEFT JOIN - Todos los registros de la izquierda + coincidencias

```sql
-- Todos los productos, incluso sin categoría
SELECT 
    p.name AS producto,
    p.listprice,
    pc.name AS categoria
FROM raw.product p
LEFT JOIN raw.productsubcategory ps 
    ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN raw.productcategory pc 
    ON ps.productcategoryid = pc.productcategoryid
LIMIT 20;
```

### Ejemplo completo: Join de 4 tablas

```sql
-- Análisis completo de ventas
SELECT 
    h.salesorderid,
    h.orderdate,
    p.name AS producto,
    pc.name AS categoria,
    d.orderqty,
    d.unitprice,
    d.linetotal
FROM raw.salesorderheader h
INNER JOIN raw.salesorderdetail d 
    ON h.salesorderid = d.salesorderid
INNER JOIN raw.product p 
    ON d.productid = p.productid
LEFT JOIN raw.productsubcategory ps 
    ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN raw.productcategory pc 
    ON ps.productcategoryid = pc.productcategoryid
WHERE h.orderdate >= DATE '2011-01-01'
LIMIT 20;
```

---

## 6️⃣ Subconsultas (Subqueries)

**Concepto**: Queries dentro de queries.

```sql
-- Productos más caros que el promedio
SELECT name, listprice
FROM raw.product
WHERE listprice > (
    SELECT AVG(listprice) 
    FROM raw.product
)
ORDER BY listprice DESC
LIMIT 10;

-- Clientes con órdenes mayores a $5000
SELECT DISTINCT customerid
FROM raw.salesorderheader
WHERE salesorderid IN (
    SELECT salesorderid
    FROM raw.salesorderdetail
    GROUP BY salesorderid
    HAVING SUM(linetotal) > 5000
)
LIMIT 10;
```

---

## 7️⃣ CTE (Common Table Expressions) - WITH

**Concepto**: Crear "tablas temporales" para queries complejas.

```sql
-- Calcular ventas por categoría usando CTE
WITH ventas_por_producto AS (
    SELECT 
        productid,
        SUM(orderqty) AS total_vendido,
        SUM(linetotal) AS total_ingresos
    FROM raw.salesorderdetail
    GROUP BY productid
)
SELECT 
    pc.name AS categoria,
    SUM(vpp.total_vendido) AS unidades_vendidas,
    SUM(vpp.total_ingresos) AS ingresos_totales
FROM ventas_por_producto vpp
INNER JOIN raw.product p 
    ON vpp.productid = p.productid
LEFT JOIN raw.productsubcategory ps 
    ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN raw.productcategory pc 
    ON ps.productcategoryid = pc.productcategoryid
WHERE pc.name IS NOT NULL
GROUP BY pc.name
ORDER BY ingresos_totales DESC;

-- Múltiples CTEs
WITH 
clientes_top AS (
    SELECT customerid, COUNT(*) AS num_ordenes
    FROM raw.salesorderheader
    GROUP BY customerid
    HAVING COUNT(*) > 5
),
productos_caros AS (
    SELECT productid, name, listprice
    FROM raw.product
    WHERE listprice > 1000
)
SELECT 
    ct.customerid,
    ct.num_ordenes,
    COUNT(DISTINCT d.productid) AS productos_distintos
FROM clientes_top ct
INNER JOIN raw.salesorderheader h 
    ON ct.customerid = h.customerid
INNER JOIN raw.salesorderdetail d 
    ON h.salesorderid = d.salesorderid
INNER JOIN productos_caros pc 
    ON d.productid = pc.productid
GROUP BY ct.customerid, ct.num_ordenes
ORDER BY productos_distintos DESC
LIMIT 10;
```

---

## 8️⃣ Funciones de Ventana (Window Functions)

**Concepto**: Cálculos sobre un "ventana" de filas sin agrupar.

### ROW_NUMBER - Numerar filas

```sql
-- Numerar productos por precio dentro de cada categoría
SELECT 
    pc.name AS categoria,
    p.name AS producto,
    p.listprice,
    ROW_NUMBER() OVER (
        PARTITION BY pc.productcategoryid 
        ORDER BY p.listprice DESC
    ) AS ranking_precio
FROM raw.product p
LEFT JOIN raw.productsubcategory ps 
    ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN raw.productcategory pc 
    ON ps.productcategoryid = pc.productcategoryid
WHERE pc.name IS NOT NULL
LIMIT 20;
```

### RANK y DENSE_RANK

```sql
-- Ranking de productos más vendidos
WITH ventas AS (
    SELECT 
        productid,
        SUM(orderqty) AS total_vendido
    FROM raw.salesorderdetail
    GROUP BY productid
)
SELECT 
    p.name,
    v.total_vendido,
    RANK() OVER (ORDER BY v.total_vendido DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY v.total_vendido DESC) AS dense_rank,
    ROW_NUMBER() OVER (ORDER BY v.total_vendido DESC) AS row_num
FROM ventas v
INNER JOIN raw.product p 
    ON v.productid = p.productid
LIMIT 10;
```

### SUM, AVG con OVER - Acumulados y promedios móviles

```sql
-- Ventas acumuladas por fecha
WITH ventas_diarias AS (
    SELECT 
        CAST(orderdate AS DATE) AS fecha,
        SUM(totaldue) AS venta_del_dia
    FROM raw.salesorderheader
    GROUP BY CAST(orderdate AS DATE)
)
SELECT 
    fecha,
    venta_del_dia,
    SUM(venta_del_dia) OVER (
        ORDER BY fecha 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS venta_acumulada,
    AVG(venta_del_dia) OVER (
        ORDER BY fecha 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS promedio_7_dias
FROM ventas_diarias
ORDER BY fecha
LIMIT 20;
```

### LAG y LEAD - Valores anteriores y siguientes

```sql
-- Comparar ventas con el día anterior
WITH ventas_diarias AS (
    SELECT 
        CAST(orderdate AS DATE) AS fecha,
        COUNT(*) AS num_ordenes,
        SUM(totaldue) AS venta_del_dia
    FROM raw.salesorderheader
    GROUP BY CAST(orderdate AS DATE)
)
SELECT 
    fecha,
    num_ordenes,
    venta_del_dia,
    LAG(venta_del_dia, 1) OVER (ORDER BY fecha) AS venta_dia_anterior,
    venta_del_dia - LAG(venta_del_dia, 1) OVER (ORDER BY fecha) AS diferencia,
    LEAD(venta_del_dia, 1) OVER (ORDER BY fecha) AS venta_dia_siguiente
FROM ventas_diarias
ORDER BY fecha
LIMIT 20;
```

---

## 9️⃣ CASE WHEN - Lógica Condicional

**Concepto**: Crear columnas con lógica if-then-else.

```sql
-- Categorizar productos por precio
SELECT 
    name,
    listprice,
    CASE 
        WHEN listprice < 100 THEN 'Económico'
        WHEN listprice BETWEEN 100 AND 500 THEN 'Medio'
        WHEN listprice BETWEEN 500 AND 1000 THEN 'Premium'
        ELSE 'Lujo'
    END AS categoria_precio
FROM raw.product
ORDER BY listprice DESC
LIMIT 20;

-- Clasificar clientes por volumen de compra
WITH compras_cliente AS (
    SELECT 
        customerid,
        COUNT(*) AS num_ordenes,
        SUM(totaldue) AS total_gastado
    FROM raw.salesorderheader
    GROUP BY customerid
)
SELECT 
    customerid,
    num_ordenes,
    total_gastado,
    CASE 
        WHEN num_ordenes >= 10 THEN 'VIP'
        WHEN num_ordenes >= 5 THEN 'Regular'
        ELSE 'Nuevo'
    END AS tipo_cliente
FROM compras_cliente
ORDER BY total_gastado DESC
LIMIT 20;
```

---

## 🔟 Funciones de Fecha

**Concepto**: Manipular y extraer información de fechas.

```sql
-- Extraer partes de fecha
SELECT 
    orderdate,
    YEAR(orderdate) AS año,
    MONTH(orderdate) AS mes,
    DAY(orderdate) AS dia,
    DATE_FORMAT(orderdate, '%Y-%m') AS año_mes,
    DATE_FORMAT(orderdate, '%W') AS dia_semana
FROM raw.salesorderheader
LIMIT 10;

-- Ventas por mes
SELECT 
    YEAR(orderdate) AS año,
    MONTH(orderdate) AS mes,
    COUNT(*) AS num_ordenes,
    SUM(totaldue) AS venta_total
FROM raw.salesorderheader
GROUP BY YEAR(orderdate), MONTH(orderdate)
ORDER BY año, mes;

-- Días desde la orden
SELECT 
    salesorderid,
    orderdate,
    DATE_DIFF('day', orderdate, CURRENT_DATE) AS dias_desde_orden
FROM raw.salesorderheader
ORDER BY orderdate DESC
LIMIT 10;
```

---

## 1️⃣1️⃣ Funciones de Texto (String)

```sql
-- Manipulación de texto
SELECT 
    name,
    UPPER(name) AS mayusculas,
    LOWER(name) AS minusculas,
    LENGTH(name) AS longitud,
    SUBSTR(name, 1, 5) AS primeros_5,
    CONCAT('Producto: ', name) AS con_prefijo
FROM raw.product
LIMIT 10;

-- Búsqueda en texto
SELECT name
FROM raw.product
WHERE LOWER(name) LIKE '%mountain%'
   OR LOWER(name) LIKE '%road%'
LIMIT 10;
```

---

## 1️⃣2️⃣ UNION - Combinar Resultados

```sql
-- Combinar productos de diferentes categorías
SELECT 'Categoría 1' AS fuente, name, listprice
FROM raw.product
WHERE listprice > 1000
LIMIT 5

UNION ALL

SELECT 'Categoría 2' AS fuente, name, listprice
FROM raw.product
WHERE color = 'Red'
LIMIT 5;
```

---

## 1️⃣3️⃣ Queries Útiles para el Proyecto

### Top 10 productos más vendidos

```sql
SELECT 
    p.name AS producto,
    SUM(d.orderqty) AS unidades_vendidas,
    SUM(d.linetotal) AS ingresos_totales
FROM raw.salesorderdetail d
INNER JOIN raw.product p 
    ON d.productid = p.productid
GROUP BY p.name
ORDER BY ingresos_totales DESC
LIMIT 10;
```

### Ventas por categoría de producto

```sql
SELECT 
    pc.name AS categoria,
    COUNT(DISTINCT d.salesorderid) AS num_ordenes,
    SUM(d.orderqty) AS unidades_vendidas,
    SUM(d.linetotal) AS ingresos_totales
FROM raw.salesorderdetail d
INNER JOIN raw.product p 
    ON d.productid = p.productid
LEFT JOIN raw.productsubcategory ps 
    ON p.productsubcategoryid = ps.productsubcategoryid
LEFT JOIN raw.productcategory pc 
    ON ps.productcategoryid = pc.productcategoryid
WHERE pc.name IS NOT NULL
GROUP BY pc.name
ORDER BY ingresos_totales DESC;
```

### Análisis de clientes

```sql
WITH stats_cliente AS (
    SELECT 
        customerid,
        MIN(orderdate) AS primera_compra,
        MAX(orderdate) AS ultima_compra,
        COUNT(*) AS num_ordenes,
        SUM(totaldue) AS total_gastado,
        AVG(totaldue) AS promedio_orden
    FROM raw.salesorderheader
    GROUP BY customerid
)
SELECT 
    customerid,
    primera_compra,
    ultima_compra,
    num_ordenes,
    total_gastado,
    promedio_orden,
    DATE_DIFF('day', primera_compra, ultima_compra) AS dias_como_cliente
FROM stats_cliente
WHERE num_ordenes > 1
ORDER BY total_gastado DESC
LIMIT 20;
```

---

## 💡 Tips Importantes

1. **Siempre usa LIMIT** en queries de exploración:
   ```sql
   SELECT * FROM tabla LIMIT 10;
   ```

2. **Athena cobra por GB escaneados**, evita `SELECT *`:
   ```sql
   -- ❌ Caro
   SELECT * FROM tabla;
   
   -- ✅ Económico
   SELECT columna1, columna2 FROM tabla;
   ```

3. **Usa EXPLAIN para ver el plan de ejecución**:
   ```sql
   EXPLAIN SELECT * FROM tabla;
   ```

4. **Filtra lo antes posible** con WHERE:
   ```sql
   -- ✅ Mejor
   SELECT * FROM tabla WHERE fecha > '2023-01-01' LIMIT 10;
   
   -- ❌ Peor (escanea toda la tabla)
   SELECT * FROM tabla LIMIT 10;
   ```

5. **Comenta tus queries complejas**:
   ```sql
   -- Calcular ventas mensuales por categoría
   SELECT 
       -- Agregar más comentarios ayuda
       categoria,
       SUM(ventas) AS total
   FROM tabla
   GROUP BY categoria;
   ```

---

## 🎓 Ejercicios Propuestos

Intenta resolver estos ejercicios tú mismo:

1. **Fácil**: Lista los 5 productos más caros
2. **Fácil**: Cuenta cuántos productos hay de cada color
3. **Medio**: Encuentra el promedio de ventas por mes en 2011
4. **Medio**: Lista los clientes que han comprado más de $10,000 en total
5. **Difícil**: Encuentra los productos que se venden juntos (mismo salesorderid)
6. **Difícil**: Calcula el ranking de productos más vendidos por categoría
7. **Avanzado**: Crea un análisis de cohortes de clientes por mes de primera compra


---

**¡Practica ejecutando estos queries en AWS Athena Console!** 🚀

Recuerda: La mejor manera de aprender SQL es practicando. Modifica estos ejemplos y experimenta.
