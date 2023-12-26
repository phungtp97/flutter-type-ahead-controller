## Flutter Type Ahead TextField

Making Facebook-like type-to-tag dynamic TextField

![ Alt text](https://media.giphy.com/media/oQ4UtBHcUULM4VbKUu/giphy.gif) / ! [](https://media.giphy.com/media/oQ4UtBHcUULM4VbKUu/giphy.gif)![ Alt text](https://media.giphy.com/media/ahdzrBHI0z4YMbIAI9/giphy.gif) / ! [](https://media.giphy.com/media/ahdzrBHI0z4YMbIAI9/giphy.gif)

#Core features
- Create callbacks that will run whenever the user types designated prefixes. And let's not forget when the user types more and more that the cursor moves out of the word that has matched prefix
- Suggest a list of data based on detected prefix. For instance, @ for friends, # for trending tags
- One TextField can handle multiple types of prefixes. For instance, it can detect @,#, and more
- Suggestion items are based on the detected prefix
- Place the suggestion dialog right at the detected prefix and when the TextField cursor is placed right after it. You can get the PrefixMatchState once the controller detected prefixes
- Move the suggestion dialog as user type which is making the offset of the TextField cursor changed. With Facebook, only the Y offset of it is variable since Facebook's suggestion dialog width is constant. TypeAheadTextFieldController supports checking the X offset because who knows, you may need it ;)
- What about if the text length is so big that the TextField scroll down. In that case, we will need to recalculate the X. My solution is to provide the TextField controller and get the position
- You can custom the TextSpan for words that match different prefixes and you can add dynamic data. For instance, UserModel or TagModel. CustomSpan will be only applied to text that added to approved data
- What if the user adds an item but then decides to delete the text? You can listen to onRemove callback to see what has been removed

#Read more: https://medium.com/@phungtp97/making-a-dynamic-type-to-tag-dialog-thats-auto-pop-up-in-flutter-3a7848b1dada
