--1. Análisis completo de ventas y beneficio por producto
--Vas a analizar las ventas y el beneficio total por categoría de producto para la cuenta "Abbot Industries" en el año 2020. Queremos saber el total de ventas de productos, cuántas unidades se vendieron, el beneficio total y el beneficio promedio por cada categoría.

SELECT category, 
       SUM(product) AS Ventas_total,  --calcula las ventas total
       SUM(profit) AS beneficio_total,  --calcula el beneficio total
       SUM(units_sold) AS unidad_total,  --total de unidades vendidas 
       AVG(profit) AS avg_por_categoria  --promedio del beneficio 
FROM SALES  
WHERE 
ACCOUNT='Abbot Industries' AND  --filtra los registros para la cuenta 'Abbot Industries'
year=2020   -- Considera únicamente los datos del año 2020
GROUP BY category;  --agrupa por cetegoria 


--2. Cálculo de pronóstico total y beneficio esperado
--Queremos calcular el pronóstico total para 2022 y el beneficio de las ventas para el primer trimestre de 2020 y el tercer trimestre de 2021, organizando los resultados por categoría. Además, es importante saber cuáles fueron las oportunidades más recientes y más antiguas para cada categoría.

--with view
SELECT 
    v.CATEGORIAS,
    v.TOTAL_FORECAST AS pronostico_total_2022, -- Pronóstico total de ventas para el año 2022
    v.TOTAL_PROFIT_OVERALL AS beneficio_total_ventas, 
    v.OLD_OPPORTUNITY AS oportunidades_mas_antiguos,
    v.YOUNG_OPPORTUNITY AS oportunidades_mas_recientes,
    SUM(CASE WHEN s.Year = 2020 AND s.Quarter_of_Year = 'Q1' THEN s.Profit --Incluye beneficios del primer trimestre de 2020
             WHEN s.Year = 2021 AND s.Quarter_of_Year = 'Q3' THEN s.Profit -- Incluye beneficios del tercer trimestre de 2021
             ELSE 0 END) AS beneficio_total_ventas_calculado -- Si no cumple ninguna condición, se asigna 0
FROM 
    category_forecast_profit_summary AS v
JOIN 
    sales AS s
ON 
    v.CATEGORIAS = s.Category
GROUP BY 
    v.CATEGORIAS, v.TOTAL_FORECAST, v.TOTAL_PROFIT_OVERALL, v.OLD_OPPORTUNITY, v.YOUNG_OPPORTUNITY;


--3. Comparación de ventas, unidades vendidas y beneficio entre industrias en APAC y EMEA
--En este ejercicio, vas a comparar las ventas, las unidades vendidas y el beneficio generado por diferentes industrias en las regiones APAC y EMEA. Queremos saber el ingreso total de productos, el número de unidades vendidas, el beneficio total y el beneficio promedio.

SELECT a.industry, a.country,
SUM(s.product) AS ingreso_total_productos, SUM(s.units_sold) AS unidades_vendidas_total,
SUM(s.profit) AS beneficio_total, AVG(s.profit) AS beneficio_promedio
FROM sales as s
JOIN accounts as a
ON s.account = a.account
WHERE a.Region IN ('APAC', 'EMEA')  --filtra las regiones APAC y EMEA 
GROUP BY a.industry,  a.country;



--4.Beneficio por tipo de empresa
--Necesitamos recuperar las cuentas cuyo pronóstico total en el año 2022 sea superior a $500,000. Luego, queremos calcular el beneficio total y clasificar el beneficio como "Alto" o "Normal" en función de si supera los $1.000.000

SELECT a.industry,
       SUM(s.profit) AS beneficio_total, 
       SUM(f.forecast_profit) AS pronostico_total,
       CASE WHEN SUM(s.profit) > 1000000 THEN 'Alto'  -- Clasifica el beneficio como "Alto" si supera $1,000,000
            ELSE 'Normal'
       END AS Clasificacion 
FROM forecasts AS f
JOIN accounts AS a ON f.account = a.account
JOIN sales AS s ON f.account = s.account 
WHERE f.account IN ( -- Filtra las cuentas
    SELECT account 
    FROM forecasts 
    WHERE year = 2022
    GROUP BY account  -- Agrupa por cuenta para poder calcular el pronóstico total por cuenta
    HAVING SUM(forecast_profit) > 500000 -- Solo incluye cuentas con un pronóstico total mayor a $500,000
)
GROUP BY a.industry
ORDER BY a.industry, SUM(s.profit);


-- 5.Beneficio acumulado por trimestre particionado por industria
--Vas a calcular el beneficio total y acumulado por trimestre para cada industria. También vamos a agregar el forecast acumulado por industria y mostrar las oportunidades más recientes y más antiguas.

SELECT a.industry, s.year, s.quarter_of_year,
SUM(s.profit) AS beneficio_total,
 -- el beneficio acumulado por industria, ordenado por año y trimestre
SUM(SUM(s.profit)) OVER(PARTITION BY a.industry ORDER BY s.year, s.quarter_of_year ) AS beneficio_acumulado, 
SUM(f.forecast_profit) AS pronostico_total, 
SUM(SUM(f.forecast_profit)) OVER(PARTITION BY a.industry ORDER BY s.year, s.quarter_of_year) AS pronostico_acumulado,
MIN(opportunity_age) AS oportunidade_mas_reciente,
MAX(opportunity_age) AS oportunidade_mas_antigua
FROM accounts AS a
JOIN sales AS s
ON a.account=s.account
JOIN forecasts AS f
ON s.account = f.account 
GROUP BY a.industry, s.quarter_of_year, s.year
ORDER BY a.industry,s.year, s.quarter_of_year;



-- caso practico 

SELECT a.industry, a.region, a.country, SUM(s.profit) AS total_profit, s.category
FROM accounts AS a 
JOIN sales AS s 
ON a.account = s.account
WHERE s.category= 'Break room'
GROUP BY a.industry, a.region, a.country,s.category
ORDER BY total_profit DESC;

--analisis exploratorio 
SELECT MAX(s.product), COUNT(s.units_sold) as numero_unit, 
COUNT(s.*) AS Num_Filas,
COUNT(DISTINCT s.account) AS Num_Clientes,
AVG(s.profit) as promedio_beneficio,
ROUND(STDDEV(s.profit)) as desv_beneficio,
MAX(s.profit) as maximo_beneficio,
MIN(s.profit) as minimo_beneficio,
SUM(v.total_mantenimiento) as total_mantenimiento,
SUM(v.total_soporte) as total_soporte,
SUM(v.total_bruto) as total_bruto,
SUM(v.total_neto) as total_neto
FROM sales as s 
JOIN vista_pais_ventas as v 
ON s.account = v.account;

--analisis profundo 


SELECT s.category, 
       SUM(s.profit) AS total_benefit, 
       AVG(s.profit) AS average_benefit
FROM sales AS s
JOIN accounts AS a
ON s.account = a.account
GROUP BY s.category
ORDER BY total_benefit DESC;


SELECT a.industry, a.region, SUM(s.profit) AS total_profit, SUM(s.units_sold) AS total_units_sold, a.country
FROM accounts AS a
JOIN sales AS s ON a.account = s.account
WHERE s.category = 'Break room'  
GROUP BY a.industry, a.region, a.country
ORDER BY total_profit DESC;

--clasificacion de paises y industry
SELECT a.country, 
       a.industry, 
       SUM(s.profit) AS total_profit, 
       SUM(s.units_sold) AS total_units_sold,
       AVG(s.profit) AS avg_profit_per_country,
       CASE WHEN SUM(s.profit) > AVG(s.profit) 
            THEN 'Gold Client'
            ELSE 'Potential Client'
       END AS "Clasification"
FROM accounts AS a
JOIN sales AS s ON a.account = s.account
WHERE s.category = 'Break room'
GROUP BY a.country, a.industry
ORDER BY total_profit DESC;

