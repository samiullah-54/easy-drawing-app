# Easy Drawing App

**Easy Drawing App** is a professional-grade, modern digital drawing and ideation tool built with Flutter. Designed with a stunning, premium "Slate & Indigo" aesthetic inspired by top-tier design systems, this application offers an incredibly smooth, offline-first drawing experience. It transforms your device into a powerful digital canvas and even supports real-time screen casting to a web browser, essentially turning your phone or tablet into a wireless drawing tablet for your laptop.

## Purpose
The purpose of Easy Drawing is to provide a fast, beautiful, and distraction-free environment for sketching, taking notes, and teaching. It is built for designers, educators, and artists who need a reliable tool to quickly capture ideas or present them live without relying on internet connectivity or complex setups.

## Core Features
*   **Premium Aesthetic:** A highly refined glassmorphic and dark mode UI (Slate & Indigo) that feels completely native and professional.
*   **100% Offline Capability:** All projects are saved securely on local device storage, completely independent of any cloud service.
*   **Real-time Screen Casting:** A built-in local HTTP and WebSocket server allows you to cast your drawing canvas directly to any web browser on the same Wi-Fi network (or via USB tethering), turning your device into an active presentation tool.
*   **Dynamic Island Action Bar:** A smart, auto-collapsing action bar that stays out of your way while drawing but provides instant access to Undo, Clear, Save, and Cast features.
*   **Rich Drawing Tools:** Smooth pen strokes with adjustable sizes, an eraser, canvas panning, and instant geometric shapes insertion.
*   **Gallery Management:** A beautiful grid-based project gallery to create, organize, and manage unlimited drawing canvases.

---

## Use Case Flow

1.  **Launch & Gallery:** Upon opening the app, you are greeted by an elegant splash screen that seamlessly transitions into the main Gallery.
2.  **Create Project:** Tap the floating "Create" button, enter a project name in the beautifully styled dialog, and instantly drop into an infinite drawing canvas.
3.  **Draw & Design:** Use the floating Tools menu on the bottom right to select drawing tools, customize colors, or change stroke thickness.
4.  **Live Presentation (Casting):** Need to present? Tap the "Cast" button in the top dynamic island. Open the provided IP address in your laptop's browser. Everything you draw is mirrored instantly in real-time.
5.  **Save & Export:** Tap "Save" in the dynamic island to secure your progress. The app handles data serialization and saves to local storage instantly.
6.  **Return to Gallery:** Tap "Gallery" at the top left. Your project is immediately visible in the gallery grid, ready to be resumed later.

---

## User Guide

### 1. Managing Projects
*   **Creating a Project:** On the main screen, tap the floating Indigo `+` button in the bottom right corner. Enter a name and press **Create**.
*   **Opening a Project:** Simply tap any project card in your grid to open it.
*   **Deleting a Project:** Long-press or tap the trash icon on a project card to delete it permanently.

### 2. Using the Canvas
*   The canvas is infinite! You can draw anywhere.
*   **Tools Menu:** Located at the bottom right. Tap the palette icon to open it. 
    *   **Pen:** Standard drawing tool.
    *   **Eraser:** Removes strokes.
    *   **Pan:** Allows you to drag and move the infinite canvas around without drawing.
    *   **Shapes:** Opens a menu to drop mathematical shapes directly onto the canvas.
    *   **Colors & Stroke:** Select from 5 predefined professional colors and adjust the stroke size slider.

### 3. The Dynamic Island (Top Action Bar)
At the top center of the canvas is the Dynamic Island. It automatically minimizes into a small pill after 4 seconds of inactivity to maximize your drawing space. Tap the pill to expand it and access:
*   **Undo:** Reverts your last stroke.
*   **Clear:** Wipes the entire canvas clean.
*   **Save:** Saves your current progress safely to your device.
*   **Cast:** Starts the live local casting server.

### 4. Casting Your Screen
1. Make sure your phone/tablet and your computer are on the **same Wi-Fi network**. Alternatively, connect them via a USB cable and enable **USB Tethering**.
2. Tap the **Cast** button in the Dynamic Island.
3. A popup will appear displaying an address (e.g., `http://192.168.1.5:8080`).
4. Type that exact address into your computer's web browser.
5. You will now see your drawing mirrored live on your computer screen!

---
*Built with Flutter*
