
# scrollable_text

A brief description of what this project does and who it's for

# scrollable_text


Scrollable Text is a Flutter package that provides a widget for automatically scrolling text, similar to the scrolling song names seen in music players. This package allows you to customize the scrolling speed and text style.
## Features

- **Automatic Scrolling**: Automatically scrolls the text with customizable speed.
- **Scrolling Modes**: Supports endless and bouncing scrolling modes.
- **Customizable Style**: Set text color, weight, alignment, and direction.
- **Faded Borders**: Optionally add faded borders on the text for a smooth transition effect.
- **Selectable Text**: Choose between selectable and non-selectable text.
- **Interval Spaces**: Define spaces between repeated text in endless mode.
## Platform Support

- **Null Safety**: This package supports null safety.
- **Supported Platforms**: Windows, macOS, Linux, Android, iOS.
#
## Getting started


## Usage

Here is a code snippet showing how to use the `ScrollableText` widget:

#

```dart
 ScrollableText(
        'This is the sample text for Flutter ScrollableText widget. ',
        mode: ScrollableTextMode.bouncing,
        velocity: Velocity(pixelsPerSecond: Offset(150, 0)),
        delayBefore: Duration(milliseconds: 500),
        numberOfReps: 5,
        pauseBetween: Duration(milliseconds: 50),
        style: TextStyle(color: Colors.green),
        textAlign: TextAlign.right,
        selectable: true,
    )
```


## 🔗 Links
[![portfolio](https://img.shields.io/badge/my_portfolio-000?style=for-the-badge&logo=ko-fi&logoColor=white)](http://hmtechs.unaux.com/)
[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/hanan0007?utm_source=share&utm_campaign=share_via&utm_content=profile&utm_medium=android_app)

