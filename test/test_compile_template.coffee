#!/usr/bin/env coffee

Router = require '../src/router'
ct = new Router().compile_template

context = name: 'Sandy', age: 59, children: [{name: 'Jorge', age: 32}, {name: 'Sol', age: 29}, {name: 'Celeste', age: 26}] 

tpl1 = """
        <h1>Hi, this is {{name}} page!</h1>
        <p>And these are my children</p>
        <ul>
        {{#children}}
          <li>{{name}} - {{age}}</li>
        {{/children}}
        </ul>
        <h3>Hobbies</h3>
        {{#hobbies}} <p> I like {{ hobbies }} </p> {{/hobbies}}
        {{^hobbies}} Regretably no hobbies so far... ;-( {{/hobbies}}
        <hr/>
        """

tpl2 = "<p>Hi, I am {{name}}</p>"

module.exports = {ct, context, tpl1, tpl2}

console.log ct(tpl1, context)

console.log "\n----------------------------------------\n"

context.hobbies = "Chess"

console.log ct(tpl1, context)

 
