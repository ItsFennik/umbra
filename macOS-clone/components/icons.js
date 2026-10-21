.pragma library

// Line icons on a 24x24 grid, drawn with round caps and joins.
var paths = {
    "wifi": "M2 8.82a15 15 0 0 1 20 0 M5 12.86a10 10 0 0 1 14 0 M8.5 16.43a5 5 0 0 1 7 0 M12 20h.01",
    "wifi-2": "M5 12.86a10 10 0 0 1 14 0 M8.5 16.43a5 5 0 0 1 7 0 M12 20h.01",
    "wifi-1": "M8.5 16.43a5 5 0 0 1 7 0 M12 20h.01",
    "wifi-off": "M12 20h.01 M8.5 16.43a5 5 0 0 1 7 0 M5 12.86a10 10 0 0 1 5.17-2.69 M19 12.86a10 10 0 0 0-2-1.52 M2 8.82a15 15 0 0 1 4.18-2.64 M22 8.82a15 15 0 0 0-11.29-3.76 M2 2l20 20",
    "ethernet": "M3 15h6v6H3z M15 15h6v6h-6z M9 3h6v6H9z M6 15v-3h12v3 M12 12V9",
    "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
    "bluetooth-off": "M17 17l-5 5v-10l-5 5 M2 2l20 20 M14.5 9.5L17 7l-5-5v4.5",
    "volume": "M11 5L6 9H2v6h4l5 4z",
    "volume-1": "M11 5L6 9H2v6h4l5 4z M15.54 8.46a5 5 0 0 1 0 7.07",
    "volume-2": "M11 5L6 9H2v6h4l5 4z M15.54 8.46a5 5 0 0 1 0 7.07 M19.07 4.93a10 10 0 0 1 0 14.14",
    "volume-x": "M11 5L6 9H2v6h4l5 4z M22 9l-6 6 M16 9l6 6",
    "sun": "M8 12a4 4 0 1 0 8 0a4 4 0 1 0-8 0 M12 2v2 M12 20v2 M4.93 4.93l1.41 1.41 M17.66 17.66l1.41 1.41 M2 12h2 M20 12h2 M6.34 17.66l-1.41 1.41 M19.07 4.93l-1.41 1.41",
    "moon": "M12 3a6 6 0 0 0 9 9a9 9 0 1 1-9-9z",
    "contrast": "M2 12a10 10 0 1 0 20 0a10 10 0 1 0-20 0 M12 2v20",
    "music": "M9 18V5l12-2v13 M3 18a3 3 0 1 0 6 0a3 3 0 1 0-6 0 M15 16a3 3 0 1 0 6 0a3 3 0 1 0-6 0",
    "play": "M7 4l13 8-13 8z",
    "pause": "M6 4h4v16H6z M14 4h4v16h-4z",
    "next": "M5 5l9 7-9 7z M19 5v14",
    "previous": "M19 19l-9-7 9-7z M5 19V5",
    "bell": "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9 M10.3 21a1.94 1.94 0 0 0 3.4 0",
    "x": "M18 6L6 18 M6 6l12 12",
    "chevron-right": "M9 18l6-6-6-6",
    "chevron-left": "M15 18l-6-6 6-6",
    "check": "M20 6L9 17l-5-5",
    "lock": "M5 11h14v10H5z M8 11V7a4 4 0 0 1 8 0v4",
    "headphones": "M3 18v-6a9 9 0 0 1 18 0v6 M3 14h4v7H3z M17 14h4v7h-4z",
    "speaker": "M6 2h12v20H6z M9 15a3 3 0 1 0 6 0a3 3 0 1 0-6 0 M12 6h.01",
    "toggles": "M7 3h10a4 4 0 0 1 0 8H7a4 4 0 0 1 0-8z M7 13h10a4 4 0 0 1 0 8H7a4 4 0 0 1 0-8z M5 7a2 2 0 1 0 4 0a2 2 0 1 0-4 0 M15 17a2 2 0 1 0 4 0a2 2 0 1 0-4 0",
    "image": "M3 3h18v18H3z M8 10a2 2 0 1 0 0-4a2 2 0 1 0 0 4 M21 15l-5-5L5 21",
    "droplet": "M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z",
    "user": "M12 12a4 4 0 1 0 0-8a4 4 0 1 0 0 8 M4 21a8 8 0 0 1 16 0",
    "cursor": "M5 3l6 17 2.5-7.5L21 10z",
    "monitor": "M3 4h18v12H3z M8 20h8 M12 16v4",
    "shapes": "M3 3h7v7H3z M17.5 3a3.5 3.5 0 1 0 0 7a3.5 3.5 0 1 0 0-7 M6.5 14l4 7h-8z M14 14h7v7h-7z",
    "search": "M10 3a7 7 0 1 0 0 14a7 7 0 1 0 0-14 M21 21l-5.5-5.5",
    "grid": "M3 3h7v7H3z M14 3h7v7h-7z M14 14h7v7h-7z M3 14h7v7H3z",
    "bolt": "M13 2L4 14h7l-1 8 9-12h-7z",
    "power": "M12 2v10 M18.36 6.64a9 9 0 1 1-12.73 0",
    "restart": "M21 12a9 9 0 1 1-2.64-6.36L21 8 M21 3v5h-5",
    "log-out": "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4 M16 17l5-5-5-5 M21 12H9"
};

// Icons drawn as solid shapes rather than outlines.
var filled = ["play", "pause", "next", "previous", "bolt", "cursor"];
