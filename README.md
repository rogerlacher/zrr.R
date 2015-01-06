zrr.R
=====

Implementation of zrr as a R shiny application
----------------------------------------------

R shiny is a very powerful framework for quickly prototyping calculation intense / BI-style web applications.
I used shiny to PoC implement zrr, demonstrating feasibility of hierarchical country- and risks- selection, 
risk aggregation and what-if calculations.
All calculation algorithms are bogus, but they suffice to demonstrate the point.

zrr.R makes use of the following technologies:

  * R
  * Javascript

The following R libraries are being used:

  * RODBC
  * reshape2
  * stringr
  * shiny
  * plyr
  * rCharts
  
rCharts, again, makes use of "Highcharts" (and other javascript libraries) for creating javascript based charts.
