## Flutter Type Ahead TextField

Making Facebook-like type-to-tag dynamic TextField. 

![ Alt text](https://media.giphy.com/media/oQ4UtBHcUULM4VbKUu/giphy.gif) / ! [](https://media.giphy.com/media/oQ4UtBHcUULM4VbKUu/giphy.gif)![ Alt text](https://media.giphy.com/media/ahdzrBHI0z4YMbIAI9/giphy.gif) / ! [](https://media.giphy.com/media/ahdzrBHI0z4YMbIAI9/giphy.gif)

# Core Features

1. **Prefix-Triggered Callbacks**
    - Create callbacks that trigger whenever the user types designated prefixes (e.g., `@`, `#`). This functionality includes handling scenarios where the cursor moves out of the word containing the matched prefix as the user types more.

2. **Dynamic Data Suggestions**
    - Suggest a list of data based on the detected prefix. For example, `@` for friends and `#` for trending tags.

3. **Multi-Prefix Detection**
    - Enable a single `TextField` to handle multiple types of prefixes, such as `@`, `#`, and more.

4. **Prefix-Based Suggestions**
    - Generate suggestion items dynamically based on the detected prefix.

5. **Contextual Suggestion Dialog**
    - Place the suggestion dialog right at the detected prefix. Ensure it appears when the `TextField` cursor is positioned directly after the prefix. You can obtain the `PrefixMatchState` once the controller detects prefixes.

6. **Responsive Suggestion Dialog**
    - Adjust the position of the suggestion dialog as the user types, accounting for changes in the offset of the `TextField` cursor. The dialog's Y offset is variable, while the width remains constant (e.g., similar to Facebook's suggestion dialog). The `TypeAheadTextFieldController` also supports checking the X offset for greater customization.

7. **Scroll Handling**
    - Recalculate the X offset if the text length becomes extensive, causing the `TextField` to scroll. This is achieved by providing the `TextField` controller and retrieving the position dynamically.

8. **Customizable TextSpan**
    - Customize the `TextSpan` for words matching different prefixes. This includes adding dynamic data, such as `UserModel` or `TagModel`. The `CustomSpan` is applied only to text that has been added to the approved data.

9. **OnRemove Callback**
    - Listen to the `onRemove` callback to handle scenarios where the user adds an item and subsequently deletes the text, allowing for appropriate adjustments based on what has been removed.


## Read more: https://medium.com/@phungtp97/making-a-dynamic-type-to-tag-dialog-thats-auto-pop-up-in-flutter-3a7848b1dada
