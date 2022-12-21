extensions [table]

turtles-own [
  fact-ids ;; list of facts this agent belong to
  is-category ;; does this node represents a category? (eg, 'Person')
  highlighted ;; when true, is highlighted
]

globals [
  facts-table ;; all facts are stored here
  facts-agents-table ;; correspondence fact-id -> agents
  selected
  ; controlling colors
  color-row
  color-col
  ; controlling shapes of links
  all-shapes
  last-shape-idx
  ; counter for facts
  num-facts
]

;; ********** shapes and colors of facts nodes
to-report unselected-concept-shape
  report "circle 2"
end

to-report selected-concept-shape
  report "circle"
end

to-report unselected-concept-color
  report gray
end

to-report selected-concept-color
  report blue
end

to-report unselected-concept-size
  report 2
end

to-report selected-concept-size-ratio
  ;; when a concept is selected, this is how much larger it will get
  report 1.25
end

to-report unselected-cat-color
  report red
end

to-report selected-cat-color
  report unselected-cat-color
end

to-report unselected-cat-shape
  report unselected-concept-shape
end

to-report selected-cat-shape
  report selected-concept-shape
end

;; **********
to create-and-add-fact [#str-desc #subject-verb-object]
  set num-facts (num-facts + 1)
  table:put facts-table (word "fact" num-facts) (list #str-desc #subject-verb-object)
end

to populate-facts
  ;; hand-fills facts
  ;; Each fact is composed by a unique key -> string (description) +  a list of atoms
  set facts-table table:make ;; all facts are stored here
  set facts-agents-table table:make ;; all facts <-> agents are stored here
  ; 'Alice is a person'
  create-and-add-fact "Alice is a person" (list "Alice" "is-instance" "person")
  ; 'Bob owns a green car' has different sub-facts:
  ; (a) Bob is a person
  create-and-add-fact "Bob is a person" (list "Bob" "is-instance" "person")
  ; (b) there exists a green car
  let car-id "car-1"
  create-and-add-fact (word car-id " is a car") (list car-id "is-instance" "car")
  create-and-add-fact "green is a color" (list "green" "is-instance" "color")
  create-and-add-fact (word car-id " is green") (list car-id "is" "green")
  ; (c) Bob owns that car
  create-and-add-fact (word "Bob owns " car-id) (list "Bob" "own" car-id)
  ; 'Alice owns a red bag' has different sub-facts:
  ; (a) Alice is a person: this is done above already
  ; (b) there exists a red bag
  let bag-id "bag-1"
  create-and-add-fact (word bag-id " is a bag") (list bag-id "is-instance" "bag")
  create-and-add-fact "red is a color" (list "red" "is-instance" "color")
  create-and-add-fact (word bag-id " is red") (list bag-id "is" "red")
  ; (c) Alice owns that bag
  create-and-add-fact (word "Alice owns " bag-id) (list "Alice" "own" bag-id)
  ; 'Alice knows Bob' TODO: revise this: maybe it is a SINGLE fact?
  create-and-add-fact "Alice knows Bob" (list "Alice" "know" "Bob")
  create-and-add-fact "Bob knows Alice" (list "Bob" "know" "Alice")
  ; 'Luis owns a blue car' has different sub-facts:
  ; (a) Luis is a person
  create-and-add-fact "Luis is a person" (list "Luis" "is-instance" "person")
  ; (b) there exists a green car
  set car-id "car-2"
  create-and-add-fact (word car-id " is a car") (list car-id "is-instance" "car")
  create-and-add-fact "blue is a color" (list "blue" "is-instance" "color")
  create-and-add-fact (word car-id " is blue") (list car-id "is" "blue")
  ; (c) Luis owns that car
  create-and-add-fact (word "Luis owns " car-id) (list "Luis" "own" car-id)
  ;
  show-facts
end

to show-facts
  ;; shows facts table in output (if exist) or in console (if no output is defined)
  (foreach table:keys facts-table [
    fact-key ->
    let sentence-and-facts table:get facts-table fact-key
    let phrase first sentence-and-facts
    let facts last sentence-and-facts
    output-print (word fact-key "-> '" phrase "' (facts: " facts ")")
    ])
end

to create-facts
  ;; creates all facts
  (foreach table:keys facts-table [
    fact-key ->
    let sentence-and-facts table:get facts-table fact-key
    let phrase first sentence-and-facts
    let facts last sentence-and-facts
    print (word "processing: " fact-key "-> '" phrase "' (facts: " facts ")")
    let agent-list (draw-fact fact-key facts)
    ;; associate fact-key -> agent-list
    table:put facts-agents-table fact-key agent-list
    print (word "added: " fact-key "-> agents: " agent-list)
    ])
end

to-report create-or-label-atom [#label #fact-id #color #is-cat]
  ;; retrieves (or creates) the atom with the specified label.
  ;; Associates #fact-id to it.
  ;; return: the id of the retrieved/created agent.
  ; let's try to find the atom
  let as-list [who] of turtles with [label = #label]
  ifelse empty? as-list [
    ; we need to create it
    let the-size unselected-concept-size
    let x-cor random-xcor
    let y-cor random-ycor
    if #is-cat [
      set the-size (the-size * 2)
      set x-cor min-pxcor + (max-pxcor - min-pxcor) / 2
      set y-cor min-pycor + (max-pycor - min-pycor) / 2
    ]
    crt 1 [
      set color #color
      set label #label
      set size the-size
      set shape unselected-concept-shape
      setxy x-cor y-cor
      set fact-ids (list #fact-id)
      set is-category #is-cat
      set highlighted false
    ]
    ;; returns its id (ie, 'who')
    let new-id (count turtles - 1)
    show (word "CREATED " #label " (id: " new-id ") -> facts: " #fact-id)
    report new-id
  ]
  [ ; else
    let found-id first as-list
    if not #is-cat [
      ; let's add this fact to its list
      ask turtle found-id [ set fact-ids insert-item 0 fact-ids #fact-id ]
      show (word "FOUND " #label " (id: " found-id ") -> added " #fact-id)
      show [fact-ids] of turtle found-id
    ]
    report found-id
  ]

end

to-report draw-fact [#fact-id #fact-list]
  ;; draws and reports the agent list
  ; id's of agents I will just create
  let c unselected-concept-color ;; next-color
  let sh next-shape
  ; is this fact a 'categorization' fact?
  ; ie, something like (A is-instance B), like: ("Alice" "is-instance" "Person")
  let is-cat (first but-first #fact-list) = "is-instance"
  ifelse is-cat [
    output-print (word #fact-list " is CATEGORIZATION")
    let cat-label (last #fact-list)
    let cat-who create-or-label-atom cat-label #fact-id unselected-cat-color true
    let instance-label (first #fact-list)
    let instance-who create-or-label-atom instance-label #fact-id c false
    ; let's link the node to its category
    ask turtle cat-who [create-link-to turtle instance-who [
      set color unselected-cat-color
      set shape "dashed"
      set thickness .2
    ]]
    ; "facts" associated with the categorization of the concepts,
    report (list cat-who instance-who)
  ]
  [ ;else: let's create the facts
    output-print (word "creating: " #fact-id "-> '" #fact-list ")")
    let agentids-in-fact map [
      atom -> create-or-label-atom atom #fact-id c false
    ] #fact-list
    ; output-show agentids-in-fact ; just some logging
    ; let's link these nodes
    (foreach but-last agentids-in-fact but-first agentids-in-fact [
      [who1 who2] -> ask turtle who1 [create-link-to turtle who2 [
        set color c
        set shape sh
        set thickness .1
    ]]])
    ; returns the ids
    report agentids-in-fact
  ]
end


;; (un-) highlighting
to turn-on [#ag-who #propagate]
  turn "on" #ag-who #propagate
end

to turn-off [#ag-who #propagate]
  turn "off" #ag-who #propagate
end

to turn [#on-or-off #ag-who #propagate]
  if [highlighted] of turtle #ag-who = not (#on-or-off = "on") [
    let is-cat ([is-category] of turtle #ag-who = true)
    let sh ""
    let co ""
    let sz ""
    ifelse #on-or-off = "on" [
      set sh (ifelse-value is-cat [selected-cat-shape] [selected-concept-shape])
      set co (ifelse-value is-cat [selected-cat-color] [selected-concept-color])
      set sz ([size] of turtle #ag-who) * selected-concept-size-ratio
    ] [
      set sh (ifelse-value is-cat [unselected-cat-shape] [unselected-concept-shape])
      set co (ifelse-value is-cat [unselected-cat-color] [unselected-concept-color])
      set sz ([size] of turtle #ag-who) / selected-concept-size-ratio
    ]
    ; let's do it!
    ask turtle #ag-who [
      set highlighted #on-or-off = "on"
      set shape sh
      set color co
      set size sz
    ]
    print (word (ifelse-value #on-or-off = "on" [""] ["un-"]) "highlighted concept " #ag-who)
    if (#propagate = true) and is-cat [
      ; get all facts with this 'who' as a head, and (un-)highlight all of them.
      (foreach table:keys facts-agents-table [
        fact-key ->
        let agents table:get facts-agents-table fact-key
        if first agents = #ag-who [
          turn #on-or-off last agents true ; #propagate
        ]
      ])
    ]
  ]
end

to turn-on-label [#ag-label]
  let as-list [who] of turtles with [label = #ag-label]
  ifelse empty? as-list [
    print (word "Agent with label '" #ag-label "' does not exist")
  ] [
    turn-on (first as-list) true ; ALWAYS 'propagate'
  ]
end


to highlight-fact
  let #fact-id user-input "which fact?"
  let i table:get-or-default facts-agents-table #fact-id "not-there"
  ifelse i = "not-there" [
    print (word "There is no FACT with id '" #fact-id "'")
  ] [
    let agents-tagged table:get facts-agents-table #fact-id
    print (word "Agents: " agents-tagged)
    foreach agents-tagged [ ag-who -> turn-on ag-who false] ; we don't propagate as we want the EXACT fact
  ]
end

to highlight-concept
  let #concept user-input "which concept?"
  turn-on-label #concept
end

to unhighlight-all
  print "unhighlight all"
  foreach [who] of turtles [ #ag-who -> turn-off #ag-who true ]
end

;;
to-report next-color
  ;; returns next color for facts
  set color-row color-row + 1
  if color-row = 14 [
    set color-col (color-col + 1) mod 10
    set color-row 0
  ]
  report color-col + (color-row * 10)
end

to-report next-shape
  ;; returns next shape for links
  set last-shape-idx ((last-shape-idx + 1) mod (length all-shapes))
  report item last-shape-idx all-shapes
end



to generic-layout-turtles
  if layout = "radial" and count turtles > 1 [
    let root-agent max-one-of turtles [ count my-links ]
    layout-radial turtles links root-agent
  ]
  if layout = "spring" [
    let springy-turtles turtles
    let factor sqrt count springy-turtles
    if factor = 0 [ set factor 1 ]
    layout-spring springy-turtles links (1 / factor) (28 / factor) (1.5 / factor)
  ]
  if layout = "circle" [
    layout-circle sort turtles max-pxcor * 0.9
  ;; layout-circle turtles (world-width / 2 - 2)
  ]
  if layout = "tutte" [
    layout-circle sort turtles max-pxcor * 0.9
    layout-tutte max-n-of (count turtles * 0.5) turtles [ count my-links ] links 12
  ]
  display
end

to layout-turtles
  ;; lays out 'category' turtles in a circle, all other
  ;; atoms as springs.

  ; 'category' turtles
  let category-turtles turtles with [is-category = true]
  layout-circle sort category-turtles ((max-pxcor - min-pxcor) / 2) * 0.9
;; layout-circle turtles (world-width / 2 - 2)
  ; 'spring'
  let springy-turtles turtles with [is-category = false]
  let factor sqrt count springy-turtles
  if factor = 0 [ set factor 1 ]
  layout-spring springy-turtles links (1 / factor) (28 / factor) (1.5 / factor)
  display
end


to drag-and-move
  ifelse mouse-down? [
    ; if the mouse is down then handle selecting and dragging
    handle-select-and-drag
  ][
    ; otherwise, make sure the previous selection is deselected
    set selected nobody
    reset-perspective
  ]
  ; layout-turtles
  display ; update the display
end


to handle-select-and-drag
  ; if no turtle is selected
  ifelse selected = nobody  [
    ; pick the closet turtle
    set selected min-one-of turtles [distancexy mouse-xcor mouse-ycor]
    ; check whether or not it's close enough
    ifelse [distancexy mouse-xcor mouse-ycor] of selected > 1 [
      set selected nobody ; if not, don't select it
    ][
      watch selected ; if it is, go ahead and `watch` it
    ]
  ][
    ; if a turtle is selected, move it to the mouse
    ask selected [ setxy mouse-xcor mouse-ycor ]
  ]
end


to setup
  clear-all
  ; controlling shapes of links
  set all-shapes (list "default") ;; (list "curve12" "curve25" "default")
  set last-shape-idx -1
  populate-facts ;; all facts are stored here
  ;; indexes for colors
  set color-row -1
  set color-col 5
  ;;
  set num-facts 0
  ;;
  set-default-shape turtles unselected-concept-shape
  ;;
  create-facts
  repeat 50 [ ; just to wait for it to converge on a shape
    layout-turtles
  ]
  set selected nobody
  ;; done!
  reset-ticks
end

;; This procedure demos the creation and deletion of edges.
;; Here we create and delete edges at random, except that
;; we try to keep the total number of links constant.
to go
  if not any? turtles [ stop ]
  ask one-of turtles
    [ create-link-with one-of other turtles ]  ;; if link already exists, nothing happens
  while [count links > number-of-links]
    [ ask one-of links [ die ] ]
  tick
end


; Public Domain:
; To the extent possible under law, Uri Wilensky has waived all
; copyright and related or neighboring rights to this model.
@#$#@#$#@
GRAPHICS-WINDOW
216
10
886
681
-1
-1
6.5545
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
100
0
100
1
1
1
ticks
30.0

BUTTON
59
124
142
157
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
10
40
189
73
number-of-nodes
number-of-nodes
0
100
30.0
1
1
NIL
HORIZONTAL

BUTTON
62
82
139
115
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
12
165
191
198
number-of-links
number-of-links
0
100
78.0
1
1
NIL
HORIZONTAL

CHOOSER
36
209
174
254
layout
layout
"circle" "spring"
1

BUTTON
7
387
207
420
NIL
drag-and-move
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
60
297
129
342
NIL
selected
17
1
11

MONITOR
59
343
155
388
NIL
count turtles
17
1
11

OUTPUT
891
13
1508
591
13

BUTTON
55
435
168
468
highlight fact
highlight-fact
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
81
527
221
560
highlight concept
highlight-concept
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
60
581
204
614
clear all highlights
unhighlight-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This example demonstrates how to make a network in NetLogo.  The network consists of a collection of nodes, some of which are connected by links.

This example doesn't do anything in particular with the nodes and links.  You can use it as the basis for your own model that actually does something with them.

## THINGS TO NOTICE

In this particular example, the links are undirected.  NetLogo supports directed links too, though.

## EXTENDING THE MODEL

Try making it so you can drag the nodes around using the mouse.

Use the turtle variable `label` to label the nodes and/or links with some information.

Try calculating some statistics about the network that forms, for example the average degree.

Try other rules for connecting nodes besides totally randomly.  For example, you could:

- Connect every node to every other node.
- Make sure each node has at least one link going in or out.
- Only connect nodes that are spatially close to each other.
- Make some nodes into "hubs" (with lots of links).

And so on.

Make two kinds of nodes, differentiated by color, then only allow links to connect two nodes that are different colors.  This makes the network "bipartite."  (You might position the two kinds of nodes in two straight lines.)

## NETLOGO FEATURES

Nodes and edges are both agents.  Nodes are turtles, edges are links.

## RELATED MODELS

* Random Network Example
* Fully Connected Network Example
* Preferential Attachment
* Small Worlds

<!-- 2004 -->
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
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

curve12
12.0
-0.2 1 1.0 0.0
0.0 1 1.0 0.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

curve25
25.0
-0.2 1 1.0 0.0
0.0 1 1.0 0.0
0.2 1 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

dashed
0.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
