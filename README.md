
<!-- README.md is generated from README.Rmd. Please edit that file -->

# bizHelpeR

<!-- badges: start -->
<!-- badges: end -->

`bizHelpeR` enthält verschiedene Helferfunktionen.  
Das sind einerseits die Farben des aktuellen CI/CD sowie einige Funktionen für 
den einfachen Einsatz in `ggplot2`.  
Zudem hilft `merger()` bzw. `dodgy_merger()` bei der schnelleren Erstellung der 
Rückmeldemappe und der Kombination der verschiedenen PDFs, die für die 
Rückmeldung der Testergebnisse nötig sind.

## Installation

Um die aktuelle Version des Packages direkt von
[GitHub](https://github.com/) zu installieren, kannst du in R den
folgenden Code ausführen:

``` r
# install.packages("remotes")
remotes::install_github("DanStuder/bizHelpeR")
```

## `merger()` und `dodgy_merger()`

_Hinweis: Die Funktionen machen genau das Gleiche, aber verwenden andere Mechanismen zum Konvertieren von Word zu PDF und zur Bearbeitung von PDF-Dateien. `dodgy_merger()` simuliert Tastaturanschläge, was etwas [dodgy](https://www.merriam-webster.com/dictionary/dodgy) ist, aber im Gegensatz zu den Funktionen aus `merger()` aktuell funktioniert._

Damit die Funktion eingesetzt werden kann, ist folgender Aufbau nötig:  
- Ein Ordner mit dem Namen des Moduls (z.B. "A")  
- Darin enthalten sind Unterordner mit den Namen der Testpersonen  
- Pro Testperson sind mindestens drei Dokumente enthalten:  
  a) Rückmeldemappe als Word im Format "Vorname Nachname Mappe.docx"  
  b) PDF mit den Ergebnissen im Format "Vorname Nachname Ergebnisse.pdf"  
  c) PDF mit den Rohdaten im Format "Vorname Nachname Rohdaten.pdf"  
  d) Evtl. Fragebogen im Format "Vorname Nachname Fragebogen.pdf" 
  e) Evtl. Q-Level. Dieses Dokument muss nicht umbenannt werden, sondern kann 
  direkt aus der Mail-Nachricht per Drag-and-Drop in den Personen-Ordner gezogen
  werden.

Ist diese Struktur für jede Person gegeben, zuerst R öffnen. Für einen 
schnelleren Start empfiehlt es sich, direkt die R-GUI zu verwenden, anstatt 
RStudio. 

```{r, eval = FALSE}
bizHelpeR::merger()
# bzw.
bizHelpeR::dodgy_merger()
```

Es öffnet sich ein Fenster, in welchem der Ordner mit dem Modulnamen angewählt 
werden muss. **Achtung: Beim `dodgy_merger()` darf nach dieser Auswahl keine 
Aktion durch den User gemacht werden! Die Funktion kopiert einen Befehl in das 
Terminal, eine Interaktion kann dazu führen, dass hier ein Fehler auftritt. 
Sobald das Terminal durch die Funktion wieder geschlossen wird, läuft die 
Funktion wieder im Hintergrund und du kannst normal weiterarbeiten.**

Anschliessend wird automatisch aus der Rückmeldemappe ein PDF generiert und die 
PDFs kombiniert und zugeschnitten.

HINWEIS! Um Zeit zu sparen, überschreibt die Funktion keine existierenden 
Dokumente.  
Wenn ein Dokument (z.B. "... Rückmeldemappe.pdf") neu erstellt werden soll, 
muss die existierende Datei gelöscht werden.

## Beispiel für die Farben

Es gibt drei Paletten für verschiedene Bereiche: - BIZ allgemein:
“BIZ” - Geschäftsbereich Laufbahn: “LB” - Geschäftsbereich Berufs- und
Studienbberatung: “BSB”

Die Farben der jeweiligen Paletten können mit
`biz_colors(palette = c("BIZ", "BSB", "LB"), ...)` aufgerufen werden:

``` r
library(bizHelpeR)
#> Warning in fun(libname, pkgname): couldn't connect to display ":0"

biz_colors("BIZ")
#>   burgund aubergine dunkelrot   rotgrau rosabeige rosabraun     monza 
#> "#59231F" "#734E4C" "#AA211F" "#B8A29A" "#EDA990" "#AF6753" "#E30613"
biz_colors("LB")
#>    hellgrau lindengruen   graugruen    hellblau    petrol 1    petrol 2 
#>   "#DFD2CF"   "#B4DAC3"   "#A6BAA7"   "#7AC1E3"   "#009CB7"   "#008998" 
#> blaugruen 1 blaugruen 2   stahlblau 
#>   "#299297"   "#007B77"   "#509CB8"
biz_colors("BSB")
#> pastellgruen    grasgruen  gelbgruen 1  gelbgruen 2     hellgelb 
#>    "#D2DCC1"    "#6C9A29"    "#C0CD23"    "#B6BE14"    "#FFF374"
```

Mit `biz_pal(palette = "BIZ", reverse = FALSE, ...)` kannst du die
Reihenfolge der Paletten umkehren und Abstufungen zwischen den gegebenen
Farben auffüllen. Z.B. beinhaltet die Palette “BIZ” 7 Farben, aber
manchmal werden mehr als 7 Farben benötigt:

``` r
biz_pal("BIZ")(12)
#>  [1] "#59231F" "#673A37" "#784947" "#95312F" "#AC3835" "#B47E78" "#C6A397"
#>  [8] "#E3A791" "#D69079" "#B46C58" "#C63A35" "#E30613"
```

Für die Verwendung in `ggplot2` kann mit `scale_color_biz` und
`scale_fill_biz` gearbeitet werden, um ganz einfach die Farben zu
übergeben:

``` r
library(ggplot2)
ggplot(iris, 
       aes(Sepal.Width, 
           Sepal.Length, 
           color = Species)) +
  geom_point(size = 4) +
  scale_color_biz()
```

<img src="man/figures/README-unnamed-chunk-3-1.png" width="100%" />

``` r
ggplot(iris, 
       aes(Sepal.Width, 
           Sepal.Length, 
           color = Sepal.Length)) +
  geom_point(size = 4, 
             alpha = .6) +
  scale_color_biz(discrete = FALSE,
                  palette = "LB")
```

<img src="man/figures/README-unnamed-chunk-4-1.png" width="100%" />

``` r
ggplot(mpg, 
       aes(manufacturer, 
           fill = manufacturer)) +
  geom_bar() +
  theme(axis.text.x = element_text(angle = 45, 
                                   hjust = 1)) +
  scale_fill_biz(palette = "BSB", 
                 guide = "none")
```

<img src="man/figures/README-unnamed-chunk-5-1.png" width="100%" />

## `alphaHacker()`

Diese Funktion soll es erleichtern, aus einem Set von Items diejenigen
zu finden, die dezente Cronbachs alpha Werte generieren. Sie sollte
lediglich explorativ eingesetzt werden. Zudem muss das Ergebnis stets
aus theoretischer Sicht überprüft werden.

``` r
data <- psych::bfi[1:5]

# Ergebnis sollte immer einem Objekt zugewiesen werden.
#   Dies erlaubt es, die genauen Item-Kombinationen anzuschauen
combinations <- alphaHacker(data, min_items = 3, n_out = 5)
combinations
#> # A tibble: 5 × 2
#>   items            alpha
#>   <list>           <dbl>
#> 1 <df [2,800 × 3]> 0.720
#> 2 <df [2,800 × 4]> 0.719
#> 3 <df [2,800 × 5]> 0.703
#> 4 <df [2,800 × 4]> 0.686
#> 5 <df [2,800 × 3]> 0.652

combinations$items[[1]] |> names()
#> [1] "A2" "A3" "A5"
```
