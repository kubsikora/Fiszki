# Fiszki
Fiszki the ultimate flashcard app for easy, fun, and effective learning. Create, customize, and master any subject on the go!

## App Colors

Here you can find all the colors used in the "Fiszki" app, for both light mode and dark mode. Additionally, you can see how we've implemented these color palettes in the code.

### Light Colors

| Name      | Color                            | Hex | RGB |
|------------------|---------------------------------|------|-----|
| backgroud_color          | ![#FAF1E6](https://via.placeholder.com/10/FAF1E6?text=+) |#FAF1E6        | rgb(250, 241, 230) |
| window_color        | ![#FDFAF6](https://via.placeholder.com/10/FDFAF6?text=+) |#FDFAF6            | rgb(253, 250, 246) |
| bonus_color | ![#E4EFE7](https://via.placeholder.com/10/E4EFE7?text=+) |#E4EFE7               | rgb(228, 239, 231) |
| focus_color          | ![#064420](https://via.placeholder.com/10/064420?text=+) |#064420    | rgb(228, 239, 231) |
| font_color     | ![#000000](https://via.placeholder.com/10/000000?text=+) |#000000            | rgb(255, 255, 255) |

![Light colors](https://i.imgur.com/5KFXxUL.png)

```flutter
Map<String, String> lightColors = {
  'background_color': '#FAF1E6',
  'window_color': '#FDFAF6',
  'bonus_color': '#E4EFE7',
  'focus_color': '#064420',
  'font_color': '#000000',
};
```



### Dark Colors

| Name      | Color                            | Hex | RGB |
|-------------|---------------------|------|-----|
| backgroud_color          | ![#040D12](https://via.placeholder.com/10/040D12?text=+)| #040D12        | rgb(4, 13, 18) |
| window_color        | ![#183D3D](https://via.placeholder.com/10/183D3D?text=+) |#183D3D            | rgb(24, 61, 61) |
| bonus_color | ![#5C8374](https://via.placeholder.com/10/5C8374?text=+) |#5C8374               | rgb(92, 131, 116) |
| focus_color          | ![#93b1a6](https://via.placeholder.com/10/93b1a6?text=+) |#93B1A6    | rgb(147, 177, 166) |
| font_color     | ![#ffffff](https://via.placeholder.com/10/ffffff?text=+) |#ffffff            | rgb(0, 0, 0) |

![Light colors](https://i.imgur.com/akhy0DP.png)

```flutter
Map<String, String> darkColors = {
  'background_color': '#040D12',
  'window_color': '#183D3D',
  'bonus_color': '#5C8374',
  'focus_color': '#93B1A6',
  'font_color': '#FFFFFF',
};
```

## Functionality 

![Main window](https://i.imgur.com/1dLedw8.png)

The main window of the application is a simple category manager with a easy layout. You can create new categories in it, delete old ones, or personalize existing ones in the way you choose.

![Main window](https://i.imgur.com/9oTYmcR.png)

After entering a created category, we can browse our flashcards. Additionally, by pressing the 'Edit Flashcard' button, we can add new ones, edit existing ones, or simply delete the ones we want.

At first, the flashcard only shows the question. Upon clicking it, the associated answer we assigned is revealed.

![Create Flashcard](https://i.imgur.com/3fbPQj5.png)