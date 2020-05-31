particulas-own[
  vel-x ; Velocidad eje X
  vel-y ; Velocidad eje Y
  force-x ; Fuerza eje X
  force-y ; Fuerza eje X
  vida
]

globals[
  step-size
  aforo-actual
  infectados-hoy
  muertos-hoy
  curados-hoy
  dia
]

patches-own[
  esMuro
  pcarga-virica
]

turtles-own[
  tcarga-virica
  lista-de-la-compra
  estado
  posicion-objetivo
  guantes
  mascarilla
  movimiento
  ha-estornudado
  edad
  muerto
  UCI
  curado
  dias
]

breed [particulas particula]
breed [personas persona]
breed [dependientes dependiente]

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; setup

to setup
  ca ; Limpiar la pantalla
  reset-ticks ; se ponen los tick a 0
  set dia 1 ; Contador dias
  set step-size 0.07 ; movimiento de las particulas
  ; dibujado de paredes

  ask patches [if pxcor >= 0 and pycor >= 0 and pxcor <= 29 and pycor <= max-pycor [set pcolor black] ] ; paredes
  ask patches [if pxcor >= 1 and pycor >= 1 and pxcor <= 28 and pycor <= max-pycor - 1 [set pcolor 9] ] ; suelo
  ask patches [if pxcor >= 30 and pycor >= 0 and pxcor <= max-pxcor and pycor <= 9 [set pcolor 116] ] ; suelo para la población
  ask patches [if pxcor >= 30 and pycor >= 10 and pxcor <= max-pxcor and pycor <= 15 [set pcolor 45] ] ; UCI
  ask patches [if pxcor >= 30 and pycor >= 16 and pxcor <= max-pxcor and pycor <= 20 [set pcolor 3] ] ; cementerio

  ; interior del supermercado
  ask patches [if pxcor > 0 and pxcor < 5 and pycor = 0 [set pcolor 9]] ; puerta
  ask patches with [pycor > 7 and pycor < 17 and (member? pxcor [4 5 8 9 12 13 16 17 20 21 24 25])] [set pcolor blue ] ; estanterias interiores
  ask patches with [pxcor = 1 and (member? pycor [8 9 10 11 12 13 14 17 18 ])] [set pcolor blue]; pared izquierda
  ask patches with [pycor = 19 and (member? pxcor [3  4 5  8 9 10 11 12 13 14 15 16 17 20 21 22 23 24 25 26])] [set pcolor blue]; pared superior
  ask patches with [pxcor = 28 and pycor > 7 and pycor < 19] [set pcolor blue]; pared derecha

  ask patches with [pcolor = blue] [set esMuro true] ; Asignar muros

  ask patches [set pcarga-virica 0] ; Inicializamos la carga virica de los muros



  ask patches with [pycor > 2 and pycor < 6 and (member? pxcor [6 10 14 18 22])] [set pcolor yellow]

  crt 5 [set breed dependientes set shape "person" set ycor 4 set color green set xcor 7 + who * 4]

  crt población [
    set breed personas
    set movimiento 1
    set estado 0
    set heading -90
    set color 87
    set label-color black
    move-to one-of patches with [pcolor = 116]
    set guantes false
    set mascarilla false
    set label tcarga-virica
    set ha-estornudado 0
    set edad 18 + random 61
    set muerto false
    set UCI false
    set curado false
    set dias 0
  ]

  set aforo-actual 0

  ask n-of floor(población * %contagio_inicial / 100) personas with [color != 16 ][set tcarga-virica 1 cambiar-label-color]
  ask n-of floor(población * %_de_guantes / 100) personas with [guantes = false ][set guantes true cambiar-label-color]
  ask n-of floor(población * %_de_mascarillas / 100) personas with [mascarilla = false ][set mascarilla true cambiar-label-color]

end

to cambiar-label-color
  ifelse tcarga-virica > 0 [set color 16][set color 87]
  let l ""
  set l word l tcarga-virica
  if mascarilla [set l word "M-" l ]
  if guantes [set l word "G-" l ]
  set label l
end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; go

to go
  if ticks = 150000 [ stop ]


  ; HACER DIARIAMENTE
  ; suponemos que un dia dura 300 tiks y el super funciona durante 24h y hay unos aspersores que echan desinfectante
  if ticks mod 300 = 0 [
    ask patches with [esMuro = true] [set pcolor blue set pcarga-virica 0]
    ask particulas [die]
    pasa-un-dia
    dibujar-graficas

    ; Reiniciamos los casos diarios
    set infectados-hoy count personas with [tcarga-virica > 0]
    set curados-hoy count personas with [curado = true]
    set muertos-hoy count personas with [muerto = true]
  ]

  ask personas with [tcarga-virica > 0 and color != 16 ] [cambiar-label-color] ; colorear a  los enfermos

  ; Colorear muros segun carga virica
  ask patches with [esMuro = true and member? pcarga-virica (range 1 5)] [set pcolor 19]
  ask patches with [esMuro = true and member? pcarga-virica (range 6 10)] [set pcolor 18]
  ask patches with [esMuro = true and member? pcarga-virica (range 11 15)] [set pcolor 17]
  ask patches with [esMuro = true and member? pcarga-virica (range 16 20)] [set pcolor 16]
  ask patches with [esMuro = true and member? pcarga-virica (range 21 25)] [set pcolor 15]
  ask patches with [esMuro = true and pcarga-virica > 25] [set pcolor 14]

  if ticks mod 2 = 0 [ask patches with [pcolor = blue + 1] [set pcolor blue]] ; Reestablecer color de los objetos seleccionados

  if aforo-actual < aforo and random 100 > 50 [
    ask one-of personas with [ xcor > 29 and not UCI and not muerto ][set lista-de-la-compra 3 + random 13]
    set aforo-actual aforo-actual + 1
  ]
  ;ask dependientes [estornuda]

  ; Contagio por contacto con particula en aire. 100% si no lleva mascarilla, proba_contagio_mascarilla% si lleva.
  ask personas with [((xcor < 29 and mascarilla = false) or (xcor < 29 and mascarilla = true and prob_contagio_mascarilla < random 100)) and ha-estornudado = 0 and random 101 < %_de_contagio and not curado] [let hay-particula 0 ask particulas in-cone 1 180 [set hay-particula 1 die] if hay-particula = 1 [set tcarga-virica tcarga-virica + 1 cambiar-label-color]]



  ;if aforo-actual > 6 and ticks mod 5 = 0  [ask n-of random 6 personas with [ xcor < 29 ] [estornuda]]

  ; Personas sin mascarilla, expulsan particulas por esturnudo cada 5 ticks y 50% probabilidad
  ask personas with [xcor < 29 and mascarilla = false and tcarga-virica > 0] [if ticks mod 5 = 0 and 50 < random 100 [estornuda]]

  compute-forces
  apply-forces
  movimiento-agente
  ask personas with [ha-estornudado > 0][set ha-estornudado ha-estornudado - 1]

  tick

end

to apply-gravity
  set force-y force-y - wind
end

to apply-forces
 ask particulas[
    let step-x vel-x * step-size * 0.1
    let step-y (vel-y - wind) * step-size * 0.1
    if vida = maxTiempo [die]
    let new-x xcor + step-x
    let new-y ycor + step-y
    if esMuro = true [ ; Entra en contacto con el muro
      set pcarga-virica pcarga-virica + 1 ; Aumenta la carga virica
      ;set pcolor red
      die  ; La particula se adhiere a la superficie
    ]
    if new-x >= 29 or new-y >= max-pycor or new-x <= min-pxcor or new-y <= min-pycor [die]
    setxy new-x new-y
  ]

end

to compute-forces
  let control 0
  ask particulas[
    set force-x 0
    set force-y 0
    apply-gravity
    set vida vida + 1
    ; CONTAGIO CONTACTO PERSONAS-PARTICULAS
    ;if vida >= 3 [ask personas in-cone 1 180 [set tcarga-virica tcarga-virica + 1 set label tcarga-virica set control 1]]
    ;if control = 1 [die]
  ]

end

to estornuda
  if tcarga-virica > 0 [ ; Solucion de mierda
    set ha-estornudado 10
    let direccion heading
    hatch-particulas num-particles [
      ;show direccion
      let acel-x 20
      let acel-y 30
      if direccion = 0 [set vel-x random 15 - 7  set vel-y (random-float 1) * acel-y]
      if direccion = 90 [set vel-x (random-float 1) * acel-x  set vel-y random 15 - 7]
      if direccion = 270 [set vel-x random 15 - 7 set vel-y (random-float 1 - 1) * acel-y]
      if direccion = -90 [set vel-x (random-float 1 - 1) * acel-x set vel-y random 15 - 7]

      ;set vel-y 10 - (random-float 20) ; velocidad y inicial
      set vida 0
      set shape "circle"
      set size random-float 0.3
      set color red
      set label ""
    ]
  ]
end

to respira
  hatch-particulas num-particles * 0.05 * tcarga-virica [
    set vel-x 10 - (random-float 20) ; velocidad x inicial
    set vel-y 5 - (random-float 10) ; velocidad y inicial
    set vida 0
    set color red
    set shape "square"
    set size 0.4
    set label ""
  ]
end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; movimiento de los agentes

to movimiento-agente
  ask personas with [(lista-de-la-compra > 0 or (lista-de-la-compra = 0 and xcor < 29 )) and not muerto and not UCI] [
    ifelse estado = 0 [
      colocar-en-la-tienda
    ][
      ifelse estado = 1 [
        movimiento-tienda-entrada
      ][
        ifelse estado = 2 [
          movimiento-tienda
        ][
          salir
        ]
      ]
    ]
  ]
end

to colocar-en-la-tienda
  set xcor random 4 + 1
  set ycor 0
  set heading 0
  set estado 1
end

to movimiento-tienda-entrada
  ifelse ycor < 7 [
    fd 1
  ][
    set estado 2
    set heading 90
  ]
end

to movimiento-tienda

  if lista-de-la-compra > 0 [
    mirar-objetos-cercanos
  ]

  ifelse lista-de-la-compra = 0 and ycor = 7 [
    set estado 3
  ][

    if xcor = 2 and (ycor = 7 or ycor >= 17) [
      set heading 90
    ]

    if xcor = 27 and (ycor = 7 or ycor >= 17) [
      set heading -90
    ]

    if movimiento = 1 [
      if ycor = 7 and member? xcor [2 3 6 7 10 11 14 15 18 19 22 23 26 27] [
        if random 100 > 75 [set heading 0 set movimiento -12]
      ]

      if ycor >= 17 and member? xcor [2 3 6 7 10 11 14 15 18 19 22 23 26 27] and heading != 180 [
        if random 100 > 75 [set heading 180 set movimiento -12]
      ]
    ]

    if ycor = 18 and heading = 0 [
      ifelse random 2 = 0 [set heading -90] [set heading 90]
    ]

    if ycor = 7 and heading = 180 [
      ifelse random 2 = 0 [set heading -90] [set heading 90]
    ]

    if movimiento < 1 [set movimiento movimiento + 1]

    fd 1
  ]
end

to mirar-objetos-cercanos
  let x 0
  let y 0
  let h heading
  let muro-infectado false
  ask patch-here [
    ask neighbors4 with [esMuro = true][
      set x pxcor
      set y pycor
      set muro-infectado pcarga-virica > 0
    ]
  ]
  if x != 0 and random 100 > 90 [
    if xcor > x [
      set heading -90
    ]
    if xcor < x [
      set heading 90
    ]
    if ycor > y [
      set heading 90
    ]

    if ycor < y [
      set heading 0
    ]

    set size 1.5
    set lista-de-la-compra lista-de-la-compra - 1


    ; Contagiar/se objeto en estanteria al tocarlo sin guantes
    if tcarga-virica > random 20 and guantes = false and not curado [ask patch x y [set pcarga-virica pcarga-virica + 1]]
    if guantes = false and muro-infectado and not curado [set tcarga-virica tcarga-virica + 1 cambiar-label-color]

    set size 1
    set heading h


  ]
end



to salir
  ifelse estado = 3 [
    ir-dependiente-1
  ][
    ifelse estado = 4[
      ir-dependiente-2
    ][
      ifelse estado = 5[
        ir-dependiente-3
      ][
        ifelse estado = 6[
          salir-1
        ][
          ifelse estado = 7[
            salir-2
          ][
            salir-3
          ]
        ]
      ]
    ]
  ]
end

to ir-dependiente-1
  set heading 180
  fd 1
  set posicion-objetivo (random 5 * 4) + 5
  ifelse xcor != posicion-objetivo[
    set estado 4
     ifelse xcor > posicion-objetivo[
          set heading -90
        ] [
          set heading 90
        ]
  ][
    set estado 5
    set heading 180
  ]
end

to ir-dependiente-2
  fd 1
  if xcor = posicion-objetivo[
    set estado 5
    set heading 180
  ]
end

to ir-dependiente-3
  fd 1
  if ycor = 4 [
    set heading 90
    set size 1.5
    set size 1
    set heading 180
    set estado 6
    set posicion-objetivo 1 + random 2
  ]
end

to salir-1
  fd 1
  if ycor = posicion-objetivo [
    set posicion-objetivo random 4 + 1
    set heading -90
    set estado 7
  ]
end

to salir-2
  fd 1
  if xcor = posicion-objetivo [
    set estado 8
    set heading 180
  ]
end

to salir-3
  fd ycor
  set posicion-objetivo 0
  set estado 0
  move-to one-of patches with [pcolor = 116]
  set aforo-actual aforo-actual - 1
end
;---------------------------------------------------------------------------------------------------
to pasa-un-dia
  set dia dia + 1
  ask personas with [tcarga-virica > 0 and not muerto and not curado and xcor > 29] [
    set dias dias + 1

    ; Muerte o Curado ;
    if dias = 15 [
      ifelse (edad >= 80 and 22 > random 100) or
      (edad >= 70 and edad < 80 and 14 > random 100) or
      (edad > 60 and edad <= 70 and 5 > random 100) or
      (edad > 50 and edad <= 60 and 1.5 > random 100) or
      (edad <= 50 and 0.5 > random 100) [Muere] [Sana]
    ]

    ; UCI ;
    if dias = 7 and not UCI [
      if ((edad > 80 and 5 > random 100) or
      (edad > 60 and edad <= 80 and 30 > random 100) or
      (edad > 50 and edad <= 60 and 20 > random 100) or
      (edad > 40 and edad <= 50 and 10 > random 100) or
      (edad <= 40 and 5 > random 100) ) and not UCI [ Ingresa ]
    ]

  ]
end

to Ingresa
  if count turtles with [UCI = true] < Camillas-UCI [
    move-to one-of patches with [pcolor = 45 and pxcor > 29]
    set UCI true
    set lista-de-la-compra 0
    set color gray
    set label ""
    set estado 0
    set posicion-objetivo 0
  ]
end

to Muere
  move-to one-of patches with [pcolor = 3]
  set muerto true
  if UCI = true [
    set UCI false
  ]
  set tcarga-virica 0
  set lista-de-la-compra 0
  set color black
  set label ""
  set estado 0
  set posicion-objetivo 0
end

to Sana
  move-to one-of patches with [pcolor = 116]
  set tcarga-virica 0
  cambiar-label-color
  set curado true
  set color green
  if UCI = true [
    set UCI false
  ]
end

to dibujar-graficas
  ask one-of turtles [
    set-current-plot "Gráfica diaria"
    set-current-plot-pen "Infectados"
    let infectados count personas with [tcarga-virica > 0] - infectados-hoy
    plot distancexy 0 infectados ]

end
@#$#@#$#@
GRAPHICS-WINDOW
197
10
1308
598
-1
-1
27.58
1
10
1
1
1
0
0
0
1
0
39
0
20
0
0
1
ticks
800.0

BUTTON
25
14
88
47
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
452
185
485
wind
wind
0
1
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
10
312
182
345
maxTiempo
maxTiempo
5
15
10.0
1
1
NIL
HORIZONTAL

SLIDER
7
148
179
181
Aforo
Aforo
0
50
15.0
1
1
NIL
HORIZONTAL

SLIDER
8
66
180
99
población
población
50
500
500.0
1
1
NIL
HORIZONTAL

SLIDER
13
401
185
434
%_de_contagio
%_de_contagio
0
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
9
188
181
221
%_de_guantes
%_de_guantes
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
9
225
181
258
%_de_mascarillas
%_de_mascarillas
0
100
40.0
1
1
NIL
HORIZONTAL

BUTTON
97
14
160
47
NIL
go\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
360
183
393
num-particles
num-particles
10
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
8
105
180
138
%contagio_inicial
%contagio_inicial
1
100
40.0
1
1
NIL
HORIZONTAL

SLIDER
8
265
184
298
prob_contagio_mascarilla
prob_contagio_mascarilla
0
100
61.0
1
1
NIL
HORIZONTAL

MONITOR
199
604
286
661
Infectados
count personas with[tcarga-virica > 0]
17
1
14

MONITOR
198
665
284
722
% Infectados
count personas with [tcarga-virica > 0] / población * 100
2
1
14

SLIDER
13
493
185
526
Camillas-UCI
Camillas-UCI
1
50
20.0
1
1
NIL
HORIZONTAL

MONITOR
289
604
346
661
UCI
count turtles with [UCI = true]
0
1
14

MONITOR
351
603
429
660
Fallecidos
count personas with [muerto = true]
1
1
14

MONITOR
434
604
506
661
Curados
count personas with [curado = true]
1
1
14

MONITOR
289
665
348
722
% UCI
count personas with [UCI = true] / población * 100
2
1
14

MONITOR
354
666
430
723
% Fallecidos
count personas with [muerto = true] / población * 100
2
1
14

MONITOR
434
666
508
723
% Curados
count personas with [curado = true] / población * 100
2
1
14

PLOT
519
602
1001
847
Gráfica acumulada
Ticks
Personas
0.0
9000.0
0.0
500.0
true
true
"" ""
PENS
"Infectados" 1.0 0 -2674135 true "" "plot count personas with [tcarga-virica > 0 and UCI != true]"
"Curados" 1.0 0 -13840069 true "" "plot count personas with [curado = true]"
"UCI" 1.0 0 -1184463 true "" "plot count personas with [UCI = true]"
"Fallecidos" 1.0 0 -16777216 true "" "plot count personas with [muerto = true]"

MONITOR
349
729
510
786
% Fallecidos / Afectados
count personas with [muerto = true] / count personas with [tcarga-virica > 0 or UCI = true or curado = true or muerto = true] * 100
2
1
14

PLOT
1025
624
1416
823
Gráfica diaria
Ticks
Personas
0.0
300.0
0.0
500.0
true
true
"" ""
PENS
"Infectados" 1.0 1 -2674135 true "" ""
"Curados" 1.0 0 -13840069 true "" ""

MONITOR
119
641
188
686
Día Actual
dia
0
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
