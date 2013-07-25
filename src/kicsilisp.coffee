do (root = exports ? @) ->
  
  stdLibrary =
    first: (x) -> x[0]
    rest: (x) -> x.slice 1
    print: -> console.log.apply null, arguments
  
  class Context
    constructor: (@scope, @parent) ->
    get: (ident) -> @scope[ident] ? (@parent.get ident if @parent?)

  special =
    let: (input, context) ->
      letContext = input[1].reduce(((acc, x) -> 
        acc.scope[x[0].value] = interpret x[1], context
        acc
      ), new Context {}, context)
      interpret input[2], letContext
    lambda: (input, context) -> ->
      lambaArguments = arguments
      lambaScope = input[1].reduce(((acc, x, i) -> 
        acc[x.value] = lambdaArguments[i]
        acc
      ), {})
      interpret input[2], new Context(lambdaScope, context)
    if: (input, context) ->
      if interpret(input[1], context)
        interpret(input[2], context)
      else
        interpret(input[3], context)

  interpretList = (input, context) ->
    if special.hasOwnProperty input[0].value
      special[input[0].value] input, context
    else
      list = input.map (x) -> interpret x, context
      if list[0] instanceof Function
        list[0].apply null, list.slice(1)
      else
        list

  interpret = (input, context) ->
    unless context?
      interpret input, new Context(stdLibrary)
    else
      if input instanceof Array
        interpretList input, context
      else
        if input.type is 'identifier'
          context.get input.value
        else
          input.value

  categorize = (input) ->
    unless isNaN parseFloat(input)
      {type: 'literal', value: parseFloat(input)}
    else
      if input[0] is '"' and input.slice(-1) is '"'
        {type:'literal', value: input.slice(1, -1)}
      else
        {type:'identifier', value: input}

  parenthesize = (input, list) ->
    unless list?
      parenthesize input, []
    else
      token = input.shift()
      unless token?
        list.pop()
      else
        if token is '('
          list.push parenthesize(input, [])
          parenthesize input, list
        else
          if token is ')' then list else parenthesize input, list.concat(categorize(token))
        

  tokenize = (input) -> 
    input.split('"').map(((x, i) ->
       if i % 2 is 0
         x.replace(/\(/g, ' ( ').replace(/\)/g, ' ) ')
       else
         x.replace /\s/g, "!whitespace!"
     )).join('"').trim().split(/\s+/).map((x) -> x.replace(/!whitespace!/g, " "))
    
  parse = (input) -> parenthesize tokenize(input)
  
  execute = (input) -> interpret parse(input)

  root.kicsiLisp = {parse, interpret, execute}
