; Propiedades de las particulas
particulas-own[
  vel-x ; Velocidad eje X
  vel-y ; Velocidad eje Y
  vida
]

; variables globales
globals[
  step-size
  aforo-actual
  infectados-hoy
  muertos-hoy
  curados-hoy
  UCI-hoy
  infectados-total
  muertos-total
  curados-total
  UCI-total
  afectados
  dia
  ticks-dia
  UCI-hasta-los-15-dias
  Muertos-hasta-los-21-dias
  muertos-50
  muertos-5060
  muertos-6070
  muertos-7080
  muertos-80
]

; propiedades de los muros
patches-own[
  esMuro
  pcarga-virica
]

; propiedades de las tortugas
turtles-own[
  tcarga-virica
  UCI
  curado
  muerto
  dias
  infectado
  edad
  genero
]

; propiedades de las personas
personas-own[
  guantes
  mascarilla
  movimiento
  ha-estornudado
  posicion-objetivo
  estado
  lista-de-la-compra
  espera
]

; las diferentes razas
breed [particulas particula]
breed [personas persona]
breed [dependientes dependiente]

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; setup

to setup
  ; Configuraciones basicas del mundo
  ca ; Limpiar la pantalla
  reset-ticks ; se ponen los tick a 0
  set ticks-dia 300 ; Duracion de un dia en ticks
  set dia 1 ; Contador dias
  set step-size 0.07 ; movimiento de las particulas
  set aforo-actual 0
  set UCI-hasta-los-15-dias 0
  set Muertos-hasta-los-21-dias 0

  set muertos-total 0
  set curados-total 0
  set UCI-total 0
  set afectados 0
  set muertos-50 0
  set muertos-5060 0
  set muertos-6070 0
  set muertos-7080 0
  set muertos-80 0


  ; dibujado de paredes
  ask patches [if pxcor >= 0 and pycor >= 0 and pxcor <= 29 and pycor <= max-pycor [set pcolor black] ] ; paredes
  ask patches [if pxcor >= 1 and pycor >= 1 and pxcor <= 28 and pycor <= max-pycor - 1 [set pcolor 9] ] ; suelo
  ask patches [if pxcor >= 30 and pycor >= 0 and pxcor <= max-pxcor and pycor <= 9 [set pcolor 116] ] ; suelo para la población
  ask patches [if pxcor >= 30 and pycor >= 10 and pxcor <= max-pxcor and pycor <= 15 [set pcolor orange] ] ; UCI
  ask patches [if pxcor >= 30 and pycor >= 16 and pxcor <= max-pxcor and pycor <= 20 [set pcolor 3] ] ; cementerio

  ; interior del supermercado
  ask patches [if pxcor > 0 and pxcor < 5 and pycor = 0 [set pcolor 9]] ; puerta
  ask patches with [pycor > 7 and pycor < 17 and (member? pxcor [4 5 8 9 12 13 16 17 20 21 24 25])] [set pcolor blue ] ; estanterias interiores
  ask patches with [pxcor = 1 and (member? pycor [8 9 10 11 12 13 14 17 18 ])] [set pcolor blue]; pared izquierda
  ask patches with [pycor = 19 and (member? pxcor [3  4 5  8 9 10 11 12 13 14 15 16 17 20 21 22 23 24 25 26])] [set pcolor blue]; pared superior
  ask patches with [pxcor = 28 and pycor > 7 and pycor < 19] [set pcolor blue]; pared derecha

  ;Se asignan la propiedad de muro a las estanterias y su carga virica
  ask patches with [pcolor = blue] [set esMuro true] ; Asignar muros
  ask patches [set pcarga-virica 0] ; Inicializamos la carga virica de los muros

  ; Dependientes y su espacio de trabajo
  ask patches with [pycor > 2 and pycor < 6 and (member? pxcor [6 10 14 18 22])] [set pcolor yellow]
  crt 5 [set breed dependientes set shape "person" set ycor 4 set color green set xcor 7 + who * 4]

  ; Generación de personas
  create-personas población [
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
    set infectado false
    set muerto false
    set UCI false
    set curado false
    set dias 0
    ifelse random 2 = 0 [set genero "M"][set genero "F"]
  ]

  ; Se establecen los enfermos y se reparten tanto los guantes como las mascarillas
  ask n-of floor(población * %contagio_inicial / 100) personas with [color != 16 ][set tcarga-virica 10 cambiar-label-color]
  ask n-of floor(población * %_de_guantes / 100) personas with [guantes = false ][set guantes true cambiar-label-color]
  ask n-of floor(población * %_de_mascarillas / 100) personas with [mascarilla = false ][set mascarilla true cambiar-label-color]

  set infectados-total count personas with [tcarga-virica > 0]

end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; funciones extra

; cambiar label de las personas
to cambiar-label-color
  ifelse tcarga-virica > 0 [set color 16][set color 87]
  let l ""
  set l word l tcarga-virica
  if mascarilla [set l word "M-" l ]
  if guantes [set l word "G-" l ]
  set label l
end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; metodo go

to go
  ; parar la simulación al final del dia 60
  if ticks = ticks-dia * 60 [ stop ]

  ; HACER DIARIAMENTE
  if ticks mod ticks-dia = 0 [
    ; Se desinfecta el supermercado
    ask patches with [esMuro = true] [set pcolor blue set pcarga-virica 0]
    ask particulas [die]

    ; comprobación de los infectados
    pasa-un-dia

    ; dibujo de graficas
    dibujar-graficas

    if ticks / ticks-dia < 15 [
      set UCI-hasta-los-15-dias UCI-hasta-los-15-dias + UCI-hoy
      set Muertos-hasta-los-21-dias Muertos-hasta-los-21-dias + muertos-hoy
    ]
    ; Reiniciamos los casos diarios
    set infectados-hoy 0
    set curados-hoy 0
    set muertos-hoy 0
    set UCI-hoy 0

    ; Actualizamos estadisticas afectados totales
    set afectados count personas with[tcarga-virica > 0 or UCI or muerto or curado]


  ]

  ; Comprobación extra por si acaso no se ha coloreado algun enfermo
  ask personas with [tcarga-virica > 0 and color != 16 ] [cambiar-label-color] ; colorear a  los enfermos

  ; Colorear muros segun carga virica
  ask patches with [esMuro = true and member? pcarga-virica (range 1 5)] [set pcolor 19]
  ask patches with [esMuro = true and member? pcarga-virica (range 6 10)] [set pcolor 18]
  ask patches with [esMuro = true and member? pcarga-virica (range 11 15)] [set pcolor 17]
  ask patches with [esMuro = true and member? pcarga-virica (range 16 20)] [set pcolor 16]
  ask patches with [esMuro = true and member? pcarga-virica (range 21 25)] [set pcolor 15]
  ask patches with [esMuro = true and pcarga-virica > 25] [set pcolor 14]

  ; Reestablecer color de los objetos coloreados
  if ticks mod 2 = 0 [ask patches with [pcolor = blue + 1] [set pcolor blue]]

  ; metemos a la gente dentro de la tienda
  if aforo-actual < aforo and random 100 > 50 [
    ask one-of personas with [ xcor > 29 and not UCI and not muerto ][set lista-de-la-compra 3 + random (numero-productos - 2) set espera lista-de-la-compra]
    set aforo-actual aforo-actual + 1
  ]

  ; Contagio por contacto con particula en aire. Marcar a infectado si no lo está
  let efectividad 0 ;
  if tipo_mascarilla = "Quirurjica" [set efectividad 10]
  if tipo_mascarilla = "FFP1" [set efectividad 78]
  if tipo_mascarilla = "FFP2" [set efectividad 92]
  if tipo_mascarilla = "FFP3" [set efectividad 98]

  ; Tener la mascarilla mal colocada es como no llevarla
  if mascarilla_mal_colocada > random 100 [set efectividad efectividad / 10]


  ask personas with [
    xcor < 29 and ((mascarilla = true and efectividad < random 100) or mascarilla = false) and ha-estornudado = 0 and not curado
  ] [

    let hay-particula 0
    let probabilidad-genero 0
    ifelse genero = "M" [set probabilidad-genero random 100][set probabilidad-genero random 130]
    if probabilidad-genero > 30 [ ; menor probabilidad de contagio en hombres
      ask particulas in-cone 1 180 [
        set hay-particula 1 die
      ]

      if hay-particula = 1 [
        set tcarga-virica tcarga-virica + 1
        cambiar-label-color
        if infectado = false [
          set infectado true set infectados-hoy infectados-hoy + 1
          output-show "se infecta con partícula en el aire"
        ]
      ]
    ]
  ]

  ; Personas sin mascarilla, expulsan particulas por esturnudo cada 5 ticks
  if ticks mod 5 = 0[
    let personas-dentro count personas with [xcor < 29 and tcarga-virica > 0]
    ask n-of (random personas-dentro) personas with [xcor < 29 and tcarga-virica > 0] [estornuda]
  ]

  ; Movimiento de particulas
  compute-forces
  apply-forces

  ; Movimiento del agente
  movimiento-agente

  ; reducción del tiempo de contaminación tras un estornudo
  ask personas with [ha-estornudado > 0][set ha-estornudado ha-estornudado - 1]

  tick
end


; ------------------------------------------------------------------------------------------------------------------------------------------------------
; particulas

to apply-forces
 ask particulas[
    let step-x vel-x * step-size * 0.1
    let step-y (vel-y + Ventilación) * step-size * 0.1 ; Efecto de la ventilación
    let extra 1
    if ancho-pasillo = 2 [set extra extra + random-float 0.2] ; tamaño del pasillo
    if vida >= floor(maxTiempo * extra) [die]
    let new-x xcor + step-x
    let new-y ycor + step-y
    if esMuro = true [ ; Entra en contacto con el muro
      set pcarga-virica pcarga-virica + 1 ; Aumenta la carga virica
      ;set pcolor red
      die  ; La particula se adhiere a la superficie
    ]
    if pcolor = black [die] ;Llega al limite del supermercado
    if new-x >= 29 or new-y >= max-pycor or new-x <= min-pxcor or new-y <= min-pycor [die]
    setxy new-x new-y
  ]

end

to compute-forces
  let control 0
  ask particulas[
    set vida vida + 1 - 0.01 * Ventilación ; Viento ayuda a dispersar las particulas más tiempo
  ]

end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; estornudo del agente

to estornuda
    set ha-estornudado 10
    let direccion heading
    let efectividad 0
    if mascarilla = true [set efectividad 100 - mascarilla_mal_colocada] ; Probabilidad de colocarse mal la mascarilla y que sea inefectiva
    if efectividad < random 100 [
      hatch-particulas num-particles * tcarga-virica / 10 [
        let acel-x 20
        let acel-y 30
        ;Particula dirigida hacia donde mira la persona que estornuda
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


; ------------------------------------------------------------------------------------------------------------------------------------------------------
; movimiento de los agentes

; primera parte de la maquina de estados
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

; Primer estado, el agente aparece en la puerta
to colocar-en-la-tienda
  set xcor random 4 + 1
  set ycor 0
  set heading 0
  set estado 1
end

; Segundo estado, el agente sube hacia arriba hacia el primer pasillo y gira su cabeza a la derecha
to movimiento-tienda-entrada
  ifelse ycor < 7 [
    fd 1
  ][
    set estado 2
    set heading 90
  ]
end

; Tercer estado, movimiento en la tienda aleatoria con restricciones para que parezca natural
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


; el agente coge el objeto de la estanteria cercana
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
    if tcarga-virica > random 20 and (guantes = false or mascarilla = false) and not curado [ask patch x y [set pcarga-virica pcarga-virica + 1]  output-show (word "infecta el objeto " x "-" y)]
    if guantes = false and muro-infectado and not curado [set tcarga-virica tcarga-virica + 1 cambiar-label-color if infectado = false [set infectado true set infectados-hoy infectados-hoy + 1 output-show (word "se infecta al tocar el objeto " x "-" y)]]

    set size 1
    set heading h


  ]
end


; Segunda parte de la maquina de estados, esta se ejecuta una vez que el agente ha cogido todos los producto y esta en la fila de abajo
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
            ifelse estado = 8[
              salir-3
            ][
              ifelse estado = 9[
                esperar
              ][
                salir-espera
              ]
            ]
          ]
        ]
      ]
    ]
  ]
end

; Cuarto estado, el agente se mueve al pasillo de los dependientes
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

; Quinto estado, el agente se mueve al pasillo del dependiente ha seleccionado en el estado anterior
to ir-dependiente-2
  fd 1
  if xcor = posicion-objetivo[
    set estado 5
    set heading 180
  ]
end

; Sexto estado, el agente se coloca en cola y va bajando hasta llegar al dependiente
to ir-dependiente-3
  let cola 0
  ask patch xcor (ycor - 1) [set cola count turtles-here with [breed != particulas]]
  if cola = 0 [ ; cola de espera
    fd 1
    if ycor = 4 [
      set heading 90
      set size 1.5
      set estado 9
    ]
  ]
end

; Los siguientes dos estados se añadieron al final, por eso tienen numeros diferentes.
; decimo estado, el agente esta pagando al dependiente
to esperar
  set espera espera - 5
  if espera <= 0 [
    set estado 10
    set espera 0
  ]
end

; onceavo estado, el agente termina de pagar y se prepara para seguir su camino
to salir-espera
  set size 1
    set heading 180
    set estado 6
    set posicion-objetivo 1 + random 2
end

; Septimo estado, el agente ha terminado de pagar, y se mueve hacia abajo al pasillo de salida
to salir-1
  fd 1
  if ycor = posicion-objetivo [
    set posicion-objetivo random 4 + 1
    set heading -90
    set estado 7
  ]
end

; Octavo estado, el agente se mueve a la izquierda hacia la salida
to salir-2
  fd 1
  if xcor = posicion-objetivo [
    set estado 8
    set heading 180
  ]
end

; Noveno estado, el agente sale del supermercado
to salir-3
  fd ycor
  set posicion-objetivo 0
  set estado 0
  move-to one-of patches with [pcolor = 116]
  set aforo-actual aforo-actual - 1
end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; Comprobación de los agentes enfermos

to pasa-un-dia

  set dia dia + 1
  ask personas with [tcarga-virica > 0 and not muerto and not curado and xcor > 29] [
    set dias dias + 1

    ifelse genero = "M" [

      ; Muerte o Curado ;
      if dias = 15 [
        ifelse (edad >= 80 and (22 > random 161 or (not UCI and 70 > random 100))) or
        (edad >= 70 and edad < 80 and (14 > random 161 or (not UCI and 60 > random 100))) or
        (edad > 60 and edad <= 70 and 5 > random 161) or
        (edad > 50 and edad <= 60 and 1.5 > random 161) or
        (edad <= 50 and 0.5 > random 161) [Muere] [Sana]
      ]

      ; UCI ;
      if dias = 7 and not UCI [
        if ((edad > 80 and 5 > random 172) or
          (edad > 60 and edad <= 80 and 30 > random 172) or
          (edad > 50 and edad <= 60 and 20 > random 172) or
          (edad > 40 and edad <= 50 and 10 > random 172) or
          (edad <= 40 and 5 > random 172) ) and not UCI [ Ingresa ]
      ]

    ][

      ; Muerte o Curado ;
      if dias = 15 [
        ifelse (edad >= 80 and (22 > random 139 or (not UCI and 70 > random 100))) or
        (edad >= 70 and edad < 80 and (14 > random 139  or (not UCI and 60 > random 100))) or
        (edad > 60 and edad <= 70 and 5 > random 139) or
        (edad > 50 and edad <= 60 and 1.5 > random 139) or
        (edad <= 50 and 0.5 > random 139) [Muere] [Sana]
      ]

      ; UCI ;
      if dias = 7 and not UCI [
        if ((edad > 80 and 5 > random 128) or
          (edad > 60 and edad <= 80 and 30 > random 128) or
          (edad > 50 and edad <= 60 and 20 > random 128) or
          (edad > 40 and edad <= 50 and 10 > random 128) or
          (edad <= 40 and 5 > random 128) ) and not UCI [ Ingresa ]
      ]

    ]
  ]

  ; Estadisticas
    output-show (word "INFECTADOS HOY: " infectados-hoy)
    output-show (word "UCI HOY: " UCI-hoy)
    output-show (word "FALLECIDOS HOY: " muertos-hoy)
    output-show (word "CURADOS HOY: " curados-hoy)
    output-show (word "- DIA " dia " -")

    set infectados-total infectados-total + infectados-hoy
    set UCI-total UCI-total + UCI-hoy
    set muertos-total muertos-total + muertos-hoy
    set curados-total curados-total + curados-hoy
end

to Ingresa
  if count turtles with [UCI = true] < Camillas-UCI [
    output-show (word "INGRESA UCI (EDAD: " edad " SEXO: " genero ")")
    move-to one-of patches with [pcolor = orange and pxcor > 29]
    set UCI true
    set UCI-hoy UCI-hoy + 1 ; Aumentamos el contador diario
    set lista-de-la-compra 0
    set color gray
    set label ""
    set estado 0
    set posicion-objetivo 0
  ]
end

to Muere
  move-to one-of patches with [pcolor = 3]
  output-show (word "MUERE (EDAD: " edad " SEXO: " genero ")")
  set muerto true
  set muertos-hoy muertos-hoy + 1 ; Aumentamos el contador
  if UCI = true [
    set UCI false
  ]
  set tcarga-virica 0
  set lista-de-la-compra 0
  set color black
  set label ""
  set estado 0
  set posicion-objetivo 0

  ; Añadir a las estadisticas
  if edad >= 80 [set muertos-80 muertos-80 + 1]
  if edad >= 70 and edad < 80 [set muertos-7080 muertos-7080 + 1]
  if edad > 60 and edad <= 70 [set muertos-6070 muertos-6070 + 1]
  if edad > 50 and edad <= 60 [set muertos-5060 muertos-5060 + 1]
  if edad <= 50 [set muertos-50 muertos-50 + 1]
end

to Sana
  move-to one-of patches with [pcolor = 116]
  output-show (word "SE CURA (EDAD: " edad " SEXO: " genero ")")
  set tcarga-virica 0
  cambiar-label-color
  set curado true
  set curados-hoy curados-hoy + 1 ; Aumentamos el contador diario
  set color green
  if UCI = true [
    set UCI false
  ]
end

; ------------------------------------------------------------------------------------------------------------------------------------------------------
; dibujo de graficas


to dibujar-graficas
  ask one-of turtles [
    set-current-plot "Gráfica diaria"
    set-current-plot-pen "Infectados"
    plotxy ticks / ticks-dia  infectados-hoy
    set-current-plot-pen "UCI"
    plotxy ticks / ticks-dia  UCI-hoy
    set-current-plot-pen "Fallecidos"
    plotxy ticks / ticks-dia  muertos-hoy
    set-current-plot-pen "Curados"
    plotxy ticks / ticks-dia  curados-hoy

  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
181
10
1278
591
-1
-1
27.24
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
17
10
80
43
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
0
432
172
465
Ventilación
Ventilación
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
0
351
172
384
maxTiempo
maxTiempo
5
15
12.0
1
1
NIL
HORIZONTAL

SLIDER
0
133
172
166
Aforo
Aforo
0
50
20.0
1
1
NIL
HORIZONTAL

SLIDER
0
51
172
84
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
0
174
172
207
%_de_guantes
%_de_guantes
0
100
87.0
1
1
NIL
HORIZONTAL

SLIDER
0
217
172
250
%_de_mascarillas
%_de_mascarillas
0
100
100.0
1
1
NIL
HORIZONTAL

BUTTON
89
10
152
43
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
0
392
172
425
num-particles
num-particles
5
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
1
92
173
125
%contagio_inicial
%contagio_inicial
1
100
38.0
1
1
NIL
HORIZONTAL

MONITOR
143
603
238
660
Infectados
infectados-total
17
1
14

MONITOR
143
666
239
723
% Infectados
infectados-total / población * 100
2
1
14

SLIDER
0
473
172
506
Camillas-UCI
Camillas-UCI
1
50
25.0
1
1
NIL
HORIZONTAL

MONITOR
245
603
303
660
UCI
UCI-total
0
1
14

MONITOR
308
603
392
660
Fallecidos
muertos-total
1
1
14

MONITOR
399
603
481
660
Curados
curados-total
1
1
14

MONITOR
245
666
304
723
% UCI
UCI-total / afectados * 100
2
1
14

MONITOR
310
666
392
723
Letalidad %
muertos-total / afectados * 100
2
1
14

MONITOR
398
666
481
723
% Curados
curados-total / afectados * 100
2
1
14

PLOT
787
603
1266
848
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
"UCI" 1.0 0 -955883 true "" "plot count personas with [UCI = true]"
"Fallecidos" 1.0 0 -16777216 true "" "plot count personas with [muerto = true]"
"Colapso Sistema" 1.0 0 -5825686 true "" "plot Camillas-UCI"

MONITOR
211
731
308
788
Mortalidad %
count personas with [muerto = true] / población * 100
2
1
14

PLOT
1273
603
1764
848
Gráfica diaria
Días
Personas
0.0
60.0
0.0
50.0
false
true
"" ""
PENS
"Infectados" 1.0 1 -2674135 true "" ""
"Curados" 1.0 1 -13840069 true "" ""
"UCI" 1.0 1 -955883 true "" ""
"Fallecidos" 1.0 1 -16777216 true "" ""

MONITOR
590
674
694
747
Día Actual
dia
0
1
18

MONITOR
130
731
203
788
Afectados
afectados
0
1
14

OUTPUT
1300
10
1764
599
11

SLIDER
0
514
172
547
ancho-pasillo
ancho-pasillo
1
2
1.0
1
1
NIL
HORIZONTAL

SLIDER
0
556
172
589
numero-productos
numero-productos
3
15
10.0
1
1
NIL
HORIZONTAL

MONITOR
0
731
124
788
Afectados actuales
count personas with [tcarga-virica > 0]
2
1
14

CHOOSER
1
258
172
303
tipo_mascarilla
tipo_mascarilla
"Quirurjica" "FFP1" "FFP2" "FFP3"
0

SLIDER
0
311
172
344
mascarilla_mal_colocada
mascarilla_mal_colocada
0
100
5.0
1
1
%
HORIZONTAL

MONITOR
0
666
138
723
 UCI a los 15 dias
UCI-hasta-los-15-dias
17
1
14

MONITOR
0
603
138
660
Muertos a los 21 dias
Muertos-hasta-los-21-dias
17
1
14

MONITOR
0
794
104
843
Fallecidos (0, 50]
muertos-50
0
1
12

MONITOR
110
794
222
843
Fallecidos (50, 60]
muertos-5060
17
1
12

MONITOR
227
794
338
843
Fallecidos (60, 70]
muertos-6070
17
1
12

MONITOR
342
794
455
843
Fallecidos (70, 80]
muertos-7080
17
1
12

MONITOR
460
794
568
843
Fallecidos (80, +]
muertos-80
17
1
12

@#$#@#$#@
## WHAT IS IT?

Modelo de un supermercado generico en el contexto de la crisis desatada por la pandemia del COVID19. Se pueden variar las caracteristicas tanto de la población como del supermercado, ofreciendo así unas estadisticas proximas a las reales y donde se pueden simular diferentes escenarios de la pandemia.

## HOW TO USE IT
### La simulación presenta dos botones:

* Setup: para inicializar el mundo el mundo
* go: para ejecutar la simulación

### La simulación presenta 13 sliders:

* poblacion: numero de personas sobre las que se realizara el estudio.
* % de contagio inicial:  establece el numero de contagios que hay inicialmente.
* aforo: numero de personas que pueden estar simultaneamente en el supermercado.
* % de guantes: establece el numero de personas que tendran guantes.
* maxTiempo: define el timepo maximo de vida de una particula.
* num-particulas: el numero maximo de particulas que echara un agente al estornudar.
* % de contagio: controla la posibilidad de que un agente respire cerca de una particula.
* Ventilación: establece la fuerza del sistema de ventilación del supermercado, que empuja las particulas hacia desde la entrada hacia arriba.
* Camillas-UCI: establece el numero máximo de personas en un hospital, en UCI.
* ancho-pasillo: considerando como 1 un pasillo basico donde la salida del aire esta mas concentrada, reducira el tiempo de vida de las particulas. Siendo 2 un pasillo mas ancho con el aire un poco mas distribuido.
* numero-productos: establece el numero maximo de productos que puede comprar el cliente, controlado de esta forma el timepo que pasara en el supermercado.
* % de mascarillas: establece el numero de personas que tendran mascarillas.
* mascarilla_mal_colocada: probabilidad de colocarse la mascarilla de forma inadeacuada, de modo que no evitará la propagación de partículas al estornudar
### Tipos de mascarilla (prob_contagio_mascarilla)
* Quirúrgicas: son las más comunes y usadas entre los ciudadanos. Se ha demostrado que no son eficaces para evitar el contagio si hay partículas en el aire, pero ayudan a retener y no propagar estas partículas al toser o estornudar.
* FFP1 (filtro  de  partículas  tipo  P1):  tienen  una  eficacia  de  filtración  mínima  del  78%.  Suelen emplearse frente a partículas de material inerte, y no se recomiendan para uso médico.
* FFP2 (filtro  de  partículas  tipo  P2):  tienen  una  eficacia  de  filtración  mínima  del  92%. Se utilizan frente a aerosoles de baja o moderada toxicidad
* FFP3 (filtro  de  partículas  tipo  P3):  tienen  una  eficacia  de  filtración  mínima  del  98%. Se utilizan frente a aerosoles de alta toxicidad.

Para ejecutar correctamente la simulación, se deben establecer los parametros de los primeros 4 sliders, ejecutar el Setup para inicializar el modelo y ejecutar el go. Los demas sliders se pueden variar durante la ejecucion.


## THINGS TO TRY

### Escenarios de simulación propuestos

#### Escenario Peor
* Setup: Un aforo máximo de personas, sin mascarilla ni guantes, con una lista de la compra con muchos productos.
* Resultado: Los infectados se disparan los primeros días, y a partir del séptimo día, cuando los síntomas aparecen, la UCI se colapsa (línea morada en la gráfica), haciendo que personas ajenas a esta enfermedad tampoco puedan ser atendidas.

#### Escenario Mejor
* Setup: Aforo reducido de personas en el supermercado (10-20), todas llevando mascarilllas FFP que protegen de las partículas inhaladas (y puestas de forma correcta), así como guantes para no contaminar los productos manipulados. Además con una lista de la compra reducida con tal de minimizar el tiempo en el supermercado.
* Resultado: los casos apenas varían a los infectados inicialmente, teniendo estos una incidencia mínima sobre el resto de la población, ya que gracias a las mascarillas FFP y los guantes, resulta muy poco probable ser contagiado.

#### Escenario realista
* Setup: Un aforo reducido de personas en el supermercado (10-20). Al entrar al supermercado, es obligatorio el uso de guantes, por lo que casi todos los clientes lo llevan (95-100%). El uso de mascarillas en supermercado es muy habitual (70-85%), aunque son de tipo quirúrgica, esto es, que no protegen de las partículas en el aire, aunque evitan expulsar partículas al exterior.  Por último, una lista reducida de productos (5-10).
* Resultado: la mayoría de afectados logran curarse. Lo más notable de esta configuración es que no llega a colapsarse el sistema sanitario. Por otro lado, la mortalidad se estima en un 2-3% lo que se ajusta bastante a los datos de España a mes de mayo. A veces, en la simulación se pueden dar varios brotes de infección, debido a la coincidencia de algún individuo infectado con otro que no lleve las medidas de protección adecuadas

#### Modificación del escenario realista 
* Setup: Mantenemos todas las características de la simulación realista con la excepción del aforo. Él cual aumentamos ligeramente. 
* Resultado: observamos una mayor letalidad y mortalidad en la población. Esto es debido a que aumenta drásticamente la probabilidad de que entre en el supermercado alguien contagiado. 


## EXTENDING THE MODEL

* En vez de una población cerrada que no interactua fuera del supermercado, establecer casas, comunidades, amigos ...
* Contar a los dependientes de la tienda dentro del estudio

## NETLOGO FEATURES

* Gestión del tiempo: se ha estimado la duración de un día en 300 ticks, de forma que se pueda ralentizar el tiempo y apreciar el movimiento de los agentes. 

* Lista de la compra: El tiempo de estancia de la persona en el supermercado, viene determinado por el número máximo de productos que va a adquirir (regulable entre 3 y 15 mediante un slider).

* Efectividad de la mascarilla: existen 4 tipos de mascarillas (1 quirúrjica que ayuda a contener el estornudo y que no se disperse, pero no protege de partículas en suspensión y 3 de tipo FFP con distinta efectividad, que a diferencia de las anteriores, protegen de las partículas al respirar). Igualmente, un factor muy importante y que resaltan los medios de información, es colocarse la mascarilla bien. No sirve de nada tener una mascarilla FFP3 si está mal colocada. Por este motivo, hemos añadido un slider que permite ajustar la probabilidad que tiene una persona de colocarse la mascarilla de forma ineficaz. Este ajuste se puede usar también para representar que, aunque las personas llevan guantes, si tocan el móvil o se llevan las manos a la cara, se pueden contagiar igualemente.
Fuente: https://www.riojasalud.es/rrhh-files/rrhh/proteccion-respiratoria-rev-3175.pdf

* Gestión de las camas de la UCI: hemos añadido un slider que permite ajustar la capacidad de camas de la UCI, de forma que si no hubiera camas de UCI para un paciente grave, no se le podría atender, aumentando la probabilidad de morir (especialmente en personas de avanzada edad). Esta situación representaría el colapso del sistema sanitario, que es uno de los escenarios más peligrosos. (Se puede visualizar en la gráfica acumulada como una línea morada).

* Diferencia entre hombres y mujeres: varios estudios afirman que los hombres tienen menos probabilidad de contagiarse, pero afrontan la enfermedad peor, presentando así una mayor letalidad, y las mujeres al contrario. Hemos reflejado esto en las probabilidades que se aplican al recuperarse de la enfermedad o morir. 
Fuentes: https://www.lavanguardia.com/vida/20200324/4874346984/hombres-mas-vulnerables-mujeres-danos-coronavirus.html
https://www.abc.es/sociedad/abci-mueren-mas-mayores-coronavirus-porque-siempre-mueren-mas-ancianos-202004070156_noticia.html

* Gestión de la carga vírica: la carga vírica es un atributo de las personas y de los objetos de las estanterías. Las personas pueden ve incrementada su carga vírica al inhalar partículas infecciosas o al tocar objetos contagiados. Igualmente, una persona con carga vírica puede estornudar y propagar estas partículas infecciosas o tocar un objeto y contagiarlo. La carga vírica determina si la persona se infecta y a la hora de estornudar, la cantidad de partículas que exuplsa.

* El movimiento del agente se ha realizado con una máquina de estados, cabe mencionar que la espera en cola se ha agregado posteriormente, por lo que los últimos dos estados no estan ordenados por orden de ejecución.
	* Estado 0: Esperando fuera. Si la lista de la compra > 0 -> Estado 1.
	* Estado 1: moviéndose arriba hasta el primer pasillo. Si esta en el pasillo -> Estado 2.
	* Estado 2: movimiento por la tienda de forma aleatoria (con restricciones para que no parezca un movimiento de abejas) y elección de productos a comprar. Si ha terminado de rellenar la lista de la compra -> Estado 3.
	* Estado 3: movimiento hasta el pasillo inferior y selección del dependiente. Una vez realizadas esas dos tareas -> Estado 4.
	* Estado 4: movimiento hacia el pasillo del dependiente. Cuando lo alcanza -> Estado 5.
	* Estado 5: movimiento hacia el dependiente (si hay alguien delante, espera). Una ves que ha alcanzado al dependiente -> Estado 9.
	* Estado 6: el agente acaba de pagar y empieza a bajar hacia la pasillo de salida. Una vez que lo alcanze -> Estado 7.
	* Estado 7: movimiento hacia la puerta de salida. Cuando la alcanze -> Estado 8
	* Estado 8: salida de la tienda. El estado se resetea a 0.
	* Estado 9: el agente espera a que el dependiente compruebe todos los productos para pagar. Cabe destacar que este proceso dura 5 productos por tick (siendo esto en la vida real aproximadamente 5 min). Una vez que termine -> Estado 10.
	* Estado 10: El dependiente ha terminado de comprobar los productos y el agente paga  -> Estado 6.

* Para el movimiento de partículas se ha considerado un estornudo común en el que las particulas están orientadas hacia delante y van decayendo con el tiempo hacia el suelo. Las velocidades y tamaños son aleatorios.

* Para el modelo del viento, se ha considerado el modelo del Lidl o Aldi que en vez de echar corrientes de aire en cada pasillo en una dirección concreta, echan de forma uniforme el aire desde el techo hacia el suelo. Por ello, el viento de base esta en valor 1 (condiciones normales) y, si lo vamos reduciendo, las particulas no irán tan rápido hacia el suelo y tendrán un tiempo de vida mayor.

* Para el ancho de pasillo se han considerado dos casos, en el primero es el pasillo estándar, donde dos personas pueden pasar algo apretadas. Y en el otro caso, tenemos los pasillos mas anchos, ofreciendo un mejor movimiento a las personas. Como en la práctica es muy raro apreciar a más de dos personas en la misma parcela, se ha aplicado esta característica a la vida de las partículas,`permitiendo así una mayor vida en el segundo caso, ya que el viento no estará tan concentrado como en el primero.

* Gestión de la ventilación del supermercado: mediante el slider "ventilación" se puede regular la fuerza del sistema de ventilación, que desplaza las partículas de la entrada hacia arriba, añadiendo una componente constante en el cálculo de la velocidad de la partícula en el eje Y y aumentando la duración de la partícula.

## CREDITS AND REFERENCES

 Víctor Manuel Rodríguez Navarro y Ihar Myshkevich

#### Bibliografía
https://www.riojasalud.es/rrhh-files/rrhh/proteccion-respiratoria-rev-3175.pdf
https://www.urgenciasyemergen.com/coronavirus-mascarillas-y-evidencia-cientifica/
https://cdn.statcdn.com/Infographic/images/normal/21772.jpeg
https://www.lavanguardia.com/vida/20200324/4874346984/hombres-mas-vulnerables-mujeres-danos-coronavirus.html
https://www.abc.es/sociedad/abci-mueren-mas-mayores-coronavirus-porque-siempre-mueren-mas-ancianos-202004070156_noticia.html
https://www.riojasalud.es/rrhh-files/rrhh/proteccion-respiratoria-rev-3175.pdf
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
