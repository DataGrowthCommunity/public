--IRVIN RICARDO RAMOS RAMOS--
--------DATA ANALYST---------
--CASO PRACTICOS RESUELTOS--

--CASO PRACTICO--

--Del ejercicio anterior se requiere a�adir otra condicion donde se muestra los precios en las mismas categorias pero 
--adicional mostrar si son con stock y sin stock (en la tabla Production.ProductInventory se encuentra el inventario
--Nota: Solo considerar para el precio alto y medio

SELECT Name, ProductID,ListPrice,
  CASE
    WHEN ListPrice > 1000 AND EXISTS (SELECT * FROM Production.ProductInventory WHERE ProductID = Production.Product.ProductID AND Quantity > 0) THEN 'Precio muy alto - �Pero todav�a en stock!'
    WHEN ListPrice > 1000 THEN 'Precio muy alto - Fuera de stock'
    WHEN ListPrice > 500 AND ListPrice <= 1000 AND EXISTS (SELECT * FROM Production.ProductInventory WHERE ProductID = Production.Product.ProductID AND Quantity > 0) THEN 'Precio medio - �En stock!'
    WHEN ListPrice > 500 AND ListPrice <= 1000 THEN 'Precio medio - Fuera de stock'
    ELSE 'Precio bajo'
  END AS 'Precio'
FROM Production.Product
ORDER BY ProductID


-- MERGE--

--PARA CONTAR LOS CAMPOS DE UNA TABLA CON ESQUEMA--
SELECT TABLE_SCHEMA, Table_Name, COUNT(*) As NumCampos
FROM Information_Schema.Columns
GROUP BY TABLE_SCHEMA, Table_Name
HAVING COUNT(*) = 3

--CASO PRACTICO--

--CTE--

--1. Realizar ventas anuales acumulativas (Sales.SalesOrderHeader)--
WITH CTE_Ventas AS (
    SELECT YEAR(OrderDate) AS Anio, SUM(SubTotal) AS TotalVenta
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate)
)
SELECT V1.Anio, V1.TotalVenta, SUM(V2.TotalVenta) AS 'Ventas acumulativas'
FROM CTE_Ventas AS V1
JOIN CTE_Ventas AS V2 ON V1.Anio >= V2.Anio
GROUP BY V1.Anio, V1.TotalVenta
ORDER BY V1.Anio



--CASO PRACTICO--

--OVER--

--1. Obtener el total acumulado por a�o y mes de las ventas  (SALES) Sales.SalesOrderHeader--

SELECT YEAR(OrderDate) AS 'A�o', 
	   MONTH(OrderDate) AS 'Mes', 
	   SUM(TotalDue) AS 'Total',  
	   SUM(SUM(TotalDue)) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS 'Total_Acumulado'
FROM Sales.SalesOrderHeader
WHERE OrderDate >= '2011-01-01' AND OrderDate < '2014-12-31'
GROUP BY YEAR(OrderDate), MONTH(OrderDate)



--2. Calcular la media movil de las ventas anuales por persona (Sales.SalesPerson) y que solo se considere los territorios null o menor a 5 (TerritoryID)--
SELECT BusinessEntityID, TerritoryID   
   ,DATEPART(yy,ModifiedDate) AS SalesYear  
   ,CONVERT(VARCHAR(20),SalesYTD,1) AS  SalesYTD  
   ,CONVERT(VARCHAR(20),AVG(SalesYTD) OVER (PARTITION BY TerritoryID   
                                            ORDER BY DATEPART(yy,ModifiedDate)   
                                           ),1) AS MovingAvg  
   ,CONVERT(VARCHAR(20),SUM(SalesYTD) OVER (PARTITION BY TerritoryID   
                                            ORDER BY DATEPART(yy,ModifiedDate)   
                                            ),1) AS CumulativeTotal  
FROM Sales.SalesPerson  
WHERE TerritoryID IS NULL OR TerritoryID < 5  
ORDER BY TerritoryID,SalesYear;

--CASO PRACTICO--

--1. USA PIVOT, Mostrar las ventas por trimestre y por a�o utilizando la tabla Sales.SalesOrderHeader 
SELECT *
FROM (
    SELECT YEAR(OrderDate) AS 'A�o'
	,DATEPART(QUARTER, OrderDate) AS 'Trimestre'
	,SubTotal
    FROM Sales.SalesOrderHeader
) AS V1
PIVOT (
    SUM(SubTotal)
    FOR Trimestre IN ([1], [2], [3], [4])
) AS V2
ORDER BY A�o;


--2. USA UNPIVOT, Mostrar las ventas por mes, trimestre y por a�o utilizando la tabla Sales.SalesOrderHeader
SELECT A�o, Trimestre, Mes, TipoVenta, Total
FROM (
    SELECT YEAR(OrderDate) AS 'A�o', 
	DATEPART(QUARTER, OrderDate) AS 'Trimestre', 
	DATEPART(MONTH, OrderDate) AS 'Mes',  
	SubTotal, 
	TaxAmt, 
	Freight
    FROM Sales.SalesOrderHeader
) AS V1
UNPIVOT (
    Total FOR TipoVenta IN (SubTotal, TaxAmt, Freight)
) AS V2
ORDER BY A�o, Trimestre, Mes, TipoVenta;


--3. USA PIVOT, Mostrar las ventas acumuladas por trimestre y por a�o utilizando la tabla Sales.SalesOrderHeader
SELECT *
FROM (
    SELECT YEAR(OrderDate) AS 'A�o', 
	DATEPART(QUARTER, OrderDate) AS 'Trimestre',
    SUM(SubTotal) OVER (PARTITION BY YEAR(OrderDate) ORDER BY DATEPART(QUARTER, OrderDate)) AS 'VentasAcumuladas'
    FROM Sales.SalesOrderHeader
) AS V1
PIVOT (
    MAX(VentasAcumuladas)
    FOR Trimestre IN ([1], [2], [3], [4])
) AS V2
ORDER BY A�o;

--LAG/LEAD--

--CASO PRACTICO--

--1. Mostrar un comparativo entre A�O, MES de las ventas totales con respecto al A�O Anterior en los a�os 2012 y 2013--
WITH CTE_Comp
AS
(
SELECT 
	DATEPART(YEAR,OrderDate) AS 'A�O',
	DATEPART(MONTH,OrderDate) AS 'MES',
	SUM(Subtotal) AS 'VentaTotal'		
FROM   Sales.SalesOrderHeader
Group BY DATEPART(YEAR,OrderDate), DATEPART(MONTH,OrderDate)
)
SELECT A�O,
		MES,
       VentaTotal , 
       LAG(VentaTotal, 12) OVER (ORDER BY A�O, MES) AS 'VentaTotal_A�oAnterior',
       ROW_NUMBER() OVER (PARTITION BY A�O ORDER BY A�O, MES) AS 'RowNumber'
FROM   CTE_Comp
WHERE A�O IN (2012,2013);
