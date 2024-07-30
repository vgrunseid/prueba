

/*///////////////////////////////////////////////////////////////////////////////////////////
A) Efectos
i. Cuál fue el efecto suscripción neto (suscripciones menos rescates) para un fondo/subcategoría/categoría en el período día/semana/mes/año/ytd/mtd/rango específico?
ii. Cuál fue el efecto precio para un fondo/categoría/subcategoría en el período día/semana/mes/año/ytd/mtd/rango específico?
///////////////////////////////////////////////////////////////////////////////////////////
*/


--i
--cubo Efecto suscripcion por nivel año  y y nivel categoria 

select  f2.nroanio , f.categoria, round(sum(c.efectosuscripcion)) as efectosuscripcion
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio , f.categoria) 
order by f2.nroanio , f.categoria

--cubo Efecto suscripcion por nivel mes  y y nivel fondo 

select f2.nromes , f.nombrefondo, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.nombrefondo) 
order by f2.nromes, f.nombrefondo 


--ii

--cubo efecto precio por nivel fecha y nivel familia , para un rango de fechas


select f2.fecha, f.familia , round(sum(c.efectoprecio)) as efectoprecio 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha, f.familia) 
order by f2.fecha, f.familia 


--cubo efecto precio por nivel semana y nivel subcategoria , para un año determinado


select  f2.semanaanio, f.subcategoria , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.subcategoria) 
order by f2.semanaanio, f.subcategoria 



/*///////////////////////////////////////////////////////////////////////////////////////////
Evolución
i. Evolución del valor de cuota parte para de un fondo determinado en el período dia/semana/mes/año/ytd/mtd/rango específico.
ii. Evolución del valor de cuota parte agregada para una familia de fondos/categoria/subcategoria en un período dia/semana/mes/año/ytd/mtd/rango específico (aquí hay que calcular un valor de cuotaparte a nivel agregado)
iii. Evolución de un determinado fondo/familia/categoria/sub-categoria (con las implicancias de construcción de cuota parte a nivel agregado) en un período dia/semana/mes/año/ytd/mtd/rango específico, ajustado por:
1. Inflación
2. Tipo de cambio oficial
3. Tipo de cambio MEP
4. Tipo de cambio CCL
iv. Evolución del patrimonio de un fondo a lo largo del tiempo divido por moneda.
/////////////////////////////////////////////////////////////////////////////////////////// */

-- i Evolucion porcentual del valor de la cuota parte por fondo para un rango de fechas determinado

select   f2.fecha, f.nombrefondo , c.valorcuotaparte , varporcentualdiaria ,varporcentualsemana, varporcentualmes, varporcentualbimestre, varporcentualcuatrimestre, varporcentualsemestre, varporcentualano 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
--group by cube ( f2.fecha, f.subcategoria) 
order by  f.nombrefondo , f2.fecha



--iii - Expresion del valor de la cuota parte por fondo en pesos, dolar ccl y dolar mep para un rango de fechas


select   f2.fecha, f.nombrefondo ,vvm.valor as ccl, vvm2.valor as mep, c.valorcuotaparte ,c.valorcuotaparte/vvm.valor as vcp_ccl, c.valorcuotaparte/vvm2.valor as vcp_mep 
--varporcentualdiaria ,varporcentualsemana, varporcentualmes, varporcentualbimestre, varporcentualcuatrimestre, varporcentualsemestre, varporcentualano 
from cotizaciones c , fondo f , fecha f2 , valores_var_macro vvm , valores_var_macro vvm2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
and vvm.codfechakey = f2.codfechakey 
and vvm.codvariablekey = 1
and vvm2.codvariablekey = 5
and vvm2.codfechakey  = f2.codfechakey 
--group by cube ( f2.fecha, f.subcategoria) 
order by  f.nombrefondo , f2.fecha


/*///////////////////////////////////////////////////////////////////////////////////////////
c. Impacto de efectos
i. Impacto de los efectos (suscripción/precio) sobre el patrimonio de cada fondo/familia/categoria/sub-categoria
ii. Impacto de los efectos (suscripción/precio) sobre Agregados monetarios.
iii. Impacto de los patrimonios totales por fondo/familia/categoría/sub-categoría
sobre agregados monetarios
///////////////////////////////////////////////////////////////////////////////////////////
*/

--i - i impacto de los efectos sobre patrimonio por fondo  y por dia  en un rango de fechas

select   f2.fecha, f.nombrefondo ,
c.valorcuotaparte * c.cantidadcuotaparte as patrimonio, c.efectoprecio, c.efectosuscripcion, 
efectoprecio / (c.valorcuotaparte * c.cantidadcuotaparte) * 100 as impacto_efecto_precio,
efectosuscripcion / (c.valorcuotaparte * c.cantidadcuotaparte) * 100 as impacto_efecto_suscripcion,
((efectoprecio + efectosuscripcion) / (c.valorcuotaparte * c.cantidadcuotaparte) * 100) as impacto_efecto_total
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
--group by cube ( f2.fecha, f.subcategoria) 
order by  f.nombrefondo , f2.fecha


-- impacto de los efectos sobre patrimonio por fondo  y por mes en un año dado (OJO!!! VER CON JUAN SI ESTA CORRECTO)

select   f2.nromes, f.nombrefondo ,
sum(c.valorcuotaparte * c.cantidadcuotaparte) as patrimonio, 
sum(c.efectoprecio), sum(c.efectosuscripcion), 
(SUM(efectoprecio) / (SUM(c.valorcuotaparte * c.cantidadcuotaparte)) * 100) as impacto_efecto_precio,
(sum(efectosuscripcion) / SUM(c.valorcuotaparte * c.cantidadcuotaparte) * 100) as impacto_efecto_suscripcion,
((SUM(efectoprecio) + SUM(efectosuscripcion)) / (SUM(c.valorcuotaparte * c.cantidadcuotaparte)) * 100) as impacto_efecto_total
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and 	f2.nroanio = :nroanio
group by   f2.nromes, f.nombrefondo
order by  f2.nromes, f.nombrefondo 




-- impacto de los efectos sobre patrimonio por categoria  y por mes en un año dado (OJO!!! VER CON JUAN SI ESTA CORRECTO)

select   f2.nromes, f.categoria ,
sum(c.valorcuotaparte * c.cantidadcuotaparte) as patrimonio, 
sum(c.efectoprecio), sum(c.efectosuscripcion), 
(SUM(efectoprecio) / (SUM(c.valorcuotaparte * c.cantidadcuotaparte)) * 100) as impacto_efecto_precio,
(sum(efectosuscripcion) / SUM(c.valorcuotaparte * c.cantidadcuotaparte) * 100) as impacto_efecto_suscripcion,
((SUM(efectoprecio) + SUM(efectosuscripcion)) / (SUM(c.valorcuotaparte * c.cantidadcuotaparte)) * 100) as impacto_efecto_total
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and 	f2.nroanio = :nroanio
group by   f2.nromes, f.categoria
order by  f2.nromes, f.categoria 


/*///////////////////////////////////////////////////////////////////////////////////////////
d. Análisis Comparado de fondo/familia/categoría/sub-categoría en cuanto a: 
1. Cuota parte
2. Patrimonio
En relación a las variaciones variables macro varias
///////////////////////////////////////////////////////////////////////////////////////////
*/

--Analisis comparado de variacion diaria de vcp respecto al variacion del dolar CCL

select   f2.fecha, f.nombrefondo , varporcentualdiaria as vardiaria_vcp, 
((vvm.valor / lag(vvm.valor, 1)  over (partition by c.codfondokey order by c.codfechakey))-1 )* 100 as vardiaria_ccl
from cotizaciones c , fondo f , fecha f2, valores_var_macro vvm 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and vvm.codfechakey = c.codfechakey 
and vvm.codvariablekey = 1
--and fecha between :varfechadesde and :varfechahasta
--group by cube ( f2.fecha, f.subcategoria) 
order by  f.nombrefondo , f2.fecha	



----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
/*
///////////////////////////////////////////////////////////////////////////////////////////
EXTRA PUNTO A 
///////////////////////////////////////////////////////////////////////////////////////////
*/


--EFECTO SUSCRIPCION

--POR AÑO

--CUBO DE DIMENSIONES AÑO, CATEGORIA


select  f2.nroanio , f.categoria, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio , f.categoria) 
order by f2.nroanio , f.categoria

--CUBO DE DIMENSIONES AÑO, FONDO

select  f2.nroanio, f.nombrefondo , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio, f.nombrefondo) 
order by f2.nroanio, f.nombrefondo 



--CUBO DE DIMENSIONES AÑO, FAMILIA

select f2.nroanio, f.familia , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio, f.familia) 
order by f2.nroanio, f.familia 


--CUBO DE DIMENSIONES AÑO, SUBCATEGORIA

select   f2.nroanio, f.subcategoria , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube ( f2.nroanio, f.subcategoria) 
order by  f2.nroanio, f.subcategoria 


----
--POR MES

--CUBO DE DIMENSIONES MES, CATEGORIA


select  f2.nromes , f.categoria, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes , f.categoria) 
order by f2.nromes, f.categoria

--CUBO DE DIMENSIONES MES, FONDO

select f2.nromes , f.nombrefondo, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.nombrefondo) 
order by f2.nromes, f.nombrefondo 



--CUBO DE DIMENSIONES MES, FAMILIA

select  f2.nromes, f.familia , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.familia) 
order by f2.nromes, f.familia 


--CUBO DE DIMENSIONES MES, SUBCATEGORIA

select  f2.nromes, f.subcategoria , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.subcategoria) 
order by f2.nromes, f.subcategoria 


-----


--POR SEMANA

--CUBO DE DIMENSIONES SEMANA, CATEGORIA


select  f2.semanaanio , f.categoria, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio , f.categoria) 
order by f2.semanaanio, f.categoria

--CUBO DE DIMENSIONES SEMANA, FONDO

select f2.semanaanio , f.nombrefondo, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.nombrefondo) 
order by f2.semanaanio, f.nombrefondo 



--CUBO DE DIMENSIONES SEMANA, FAMILIA

select  f2.semanaanio, f.familia , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.familia) 
order by f2.semanaanio, f.familia 


--CUBO DE DIMENSIONES SEMANA, SUBCATEGORIA

select  f2.semanaanio, f.subcategoria , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.subcategoria) 
order by f2.semanaanio, f.subcategoria 



------

--RANGO DE FECHA



--CUBO DE DIMENSIONES RANGO DE FECHA, CATEGORIA


select  f2.fecha , f.categoria, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha , f.categoria) 
order by f2.fecha , f.categoria

--CUBO DE DIMENSIONES RANGO DE FECHA, FONDO

select  f2.fecha, f.nombrefondo , round(sum(c.efectosuscripcion)) as suma_efecto_suscrip 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha, f.nombrefondo) 
order by f2.fecha, f.nombrefondo 




--CUBO DE DIMENSIONES RANGO DE FECHA, FAMILIA

select f2.fecha, f.familia , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha, f.familia) 
order by f2.fecha, f.familia 


--CUBO DE DIMENSIONES RANGO DE FECHA, SUBCATEGORIA

select   f2.fecha, f.subcategoria , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube ( f2.fecha, f.subcategoria) 
order by  f2.fecha, f.subcategoria 

select * from tmp_vars_macro tvm 


--POR MES PARA TODOS LOS AÑOS PARA UN RANGO DE FECHA

--CUBO DE DIMENSIONES AÑOS, CATEGORIA


select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.categoria, round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.categoria) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.categoria

--CUBO DE DIMENSIONES AÑOS, FONDO

select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.nombrefondo , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.nombrefondo) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.nombrefondo 



--CUBO DE DIMENSIONES AÑOS, FAMILIA

select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.familia , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.familia) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.familia 


--CUBO DE DIMENSIONES AÑOS, SUBCATEGORIA

select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.subcategoria , round(sum(c.efectosuscripcion)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.subcategoria) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.subcategoria 

--------------------------------------------------------------------------
--------------------------------------------------------------------------
--------------------------------------------------------------------------

--EFECTO PRECIO

--POR AÑO

--CUBO DE DIMENSIONES AÑO, CATEGORIA


select  f2.nroanio , f.categoria, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio , f.categoria) 
order by f2.nroanio , f.categoria

--CUBO DE DIMENSIONES AÑO, FONDO

select  f2.nroanio, f.nombrefondo , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio, f.nombrefondo) 
order by f2.nroanio, f.nombrefondo 



--CUBO DE DIMENSIONES AÑO, FAMILIA

select f2.nroanio, f.familia , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (f2.nroanio, f.familia) 
order by f2.nroanio, f.familia 


--CUBO DE DIMENSIONES AÑO, SUBCATEGORIA

select   f2.nroanio, f.subcategoria , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube ( f2.nroanio, f.subcategoria) 
order by  f2.nroanio, f.subcategoria 


----
--POR MES

--CUBO DE DIMENSIONES MES, CATEGORIA


select  f2.nromes , f.categoria, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes , f.categoria) 
order by f2.nromes, f.categoria

--CUBO DE DIMENSIONES MES, FONDO

select f2.nromes , f.nombrefondo, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.nombrefondo) 
order by f2.nromes, f.nombrefondo 



--CUBO DE DIMENSIONES MES, FAMILIA

select  f2.nromes, f.familia , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.familia) 
order by f2.nromes, f.familia 


--CUBO DE DIMENSIONES MES, SUBCATEGORIA

select  f2.nromes, f.subcategoria , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.nromes, f.subcategoria) 
order by f2.nromes, f.subcategoria 


-----


--POR SEMANA

--CUBO DE DIMENSIONES SEMANA, CATEGORIA


select  f2.semanaanio , f.categoria, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio , f.categoria) 
order by f2.semanaanio, f.categoria

--CUBO DE DIMENSIONES SEMANA, FONDO

select f2.semanaanio , f.nombrefondo, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.nombrefondo) 
order by f2.semanaanio, f.nombrefondo 



--CUBO DE DIMENSIONES SEMANA, FAMILIA

select  f2.semanaanio, f.familia , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.familia) 
order by f2.semanaanio, f.familia 


--CUBO DE DIMENSIONES SEMANA, SUBCATEGORIA

select  f2.semanaanio, f.subcategoria , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and f2.nroanio = :varanio
group by cube (f2.semanaanio, f.subcategoria) 
order by f2.semanaanio, f.subcategoria 



------

--RANGO DE FECHA



--CUBO DE DIMENSIONES RANGO DE FECHA, CATEGORIA


select  f2.fecha , f.categoria, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha , f.categoria) 
order by f2.fecha , f.categoria

--CUBO DE DIMENSIONES RANGO DE FECHA, FONDO

select  f2.fecha, f.nombrefondo , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha, f.nombrefondo) 
order by f2.fecha, f.nombrefondo 



--CUBO DE DIMENSIONES RANGO DE FECHA, FAMILIA

select f2.fecha, f.familia , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube (f2.fecha, f.familia) 
order by f2.fecha, f.familia 


--CUBO DE DIMENSIONES RANGO DE FECHA, SUBCATEGORIA

select   f2.fecha, f.subcategoria , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
and fecha between :varfechadesde and :varfechahasta
group by cube ( f2.fecha, f.subcategoria) 
order by  f2.fecha, f.subcategoria 




--POR MES PARA TODOS LOS AÑOS

--CUBO DE DIMENSIONES AÑOS, CATEGORIA


select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.categoria, round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.categoria) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.categoria

--CUBO DE DIMENSIONES AÑOS, FONDO

select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.nombrefondo , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.nombrefondo) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.nombrefondo 



--CUBO DE DIMENSIONES AÑOS, FAMILIA

select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.familia , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.familia) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.familia 


--CUBO DE DIMENSIONES AÑOS, SUBCATEGORIA

select  to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.subcategoria , round(sum(c.efectoprecio)) 
from cotizaciones c , fondo f , fecha f2 
where c.codfondokey  = f.codfondokey 
and c.codfechakey = f2.codfechakey  
group by cube (to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.subcategoria) 
order by to_char(f2.nroanio, 'FM0000') || '-' || to_char(f2.nromes, 'FM00'), f.subcategoria 



