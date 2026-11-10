<!-- gf-brief source=39f42e8bb95ee6ad7b6edc91b29f7a919c594bdd317f2803ea41f9c0c678c382 written=2026-11-10T19:27:46+03:00 -->
# IcePantryOrbit

## What it is

IcePantryOrbit is a pantry inventory and shopping-list app for people who want to keep track of food quantities and the dates printed on packages. It lets them record food used or discarded, review their history, and check off shopping items on an iPhone or Apple Watch.

## Launch and onboarding

On a fresh launch, the app opens directly to the “Shelves” tab. There is no onboarding sequence.

The screen shows “The pantry”, “The pantry press”, “Shelf almanac”, “From market to meal”, and the “Add a batch” button. Under “On the shelves”, it shows “0 batches” and the empty state “Start your first shelf” with “Choose a product, enter the quantity, and record the date on the pack.” The other tabs are “Market” and “Ledger”.

## Screens

### “Shelves” — “The pantry”

- “Add a batch” opens “New batch”.
- Once batches exist, the top card shows the batch with the earliest printed date. Its date label opens “Batch details”. Date labels include “Today”, “Tomorrow”, “In [number] days”, and “[number]d overdue”.
- “On the shelves” shows the batch count and lists batches in date order. Tapping a batch opens “Batch details”.
- “All”, “Cupboard”, “Fridge”, and “Freezer” filter the list by storage location.
- “Search your shelves” filters by product name.
- The date-filter button has the accessibility label “Only show batches due within three days”; when selected, it shows “Overdue or due in three days” and its accessibility label changes to “Show all dates”.
- If filters produce no results, the screen shows “No matching batches” and “Try another storage location or change your search.”

### “New batch” and “Edit batch”

- “Close” dismisses the form.
- “Search or scan a barcode” opens “Food catalog”. The form also says “Look up the package in Open Food Facts or type a name below.”
- “Product name” accepts a name. “Brand” appears when a selected product has one.
- “Quantity” can be typed or adjusted with the controls labelled for accessibility “Decrease quantity” and “Increase quantity”.
- “Unit” offers “pcs”, “g”, and “ml”. “Storage” offers “Cupboard”, “Fridge”, and “Freezer”.
- “Label date” selects a date. The accompanying instruction is “Use the date printed on this particular package.”
- “Add to shelf” saves a new batch; “Save changes” saves an existing one. A new form starts at a quantity of 1, “pcs”, “Cupboard”, and the current date.

### “Batch details”

The screen shows the product name, storage location, quantity, date status, “Label date”, and brand when available. “Close” returns to the shelves.

- “View on Open Food Facts ↗” opens the product’s Open Food Facts page when a numeric barcode is available.
- “Edit batch” opens “Edit batch”.
- Under “Record a movement”, “Use” and “Discard” select the action. “Quantity” sets the amount, and “All” fills in the full remaining amount.
- “Add to shopping list” optionally adds the product name to “Market”.
- “Record use” records the movement immediately. “Record waste” opens a confirmation titled “Discard [quantity] [unit]?” with “Discard” and “Cancel”. Recording a movement returns to the shelves.

### “Food catalog”

This screen opens from “Search or scan a barcode” or from “Find a packaged product” on “Market”.

- “Name, brand or barcode” filters products already on the device. “Clear search” clears the field.
- “Search Open Food Facts” searches online. While searching, the screen shows “Searching the catalog…”. Results appear under “Search results”; locally available products appear under “On this device”. Tapping a product selects it and returns to the preceding flow.
- “Scan a barcode” opens “Barcode scanner”.
- “Enter label by hand” opens “New product”.
- “Close” dismisses the catalog.
- The attribution reads “Product data comes from Open Food Facts contributors. Check the package for the current ingredients.” The link “Open Food Facts · Data ODbL · Photos CC BY-SA” opens the data and photo terms.

### “New product”

“Product name” and “Brand” accept product details. Under “Per 100 g”, the optional fields are “Energy, kcal”, “Protein, g”, “Carbohydrates, g”, and “Fat, g”; the instruction says “Leave a field empty if the value is missing from the label.” Under “Ingredients”, “Ingredient list from the package” accepts text.

“Use this product” selects the entry and returns to the originating flow. The standard back control returns to “Food catalog”.

### “Barcode scanner”

“Point the camera at the product barcode” appears while scanning. A recognized code closes the scanner and searches the catalog. “Close” returns to “Food catalog”.

When scanning is unavailable, “Scanner unavailable” appears with an explanation. “Back to search” returns to the catalog; “Open Settings” is offered when camera access has been denied.

### “Market” — “Market list”

The screen says “Plan your trip here. Check items off in the aisle using your phone or Apple Watch.”

- “What do you need?” accepts an item. The plus button, labelled for accessibility “Add to shopping list”, adds it to “To pick up”.
- “Find a packaged product” opens “Food catalog”; selecting a product adds its name to the list.
- Tapping an item checks it off or returns it to “To pick up”. Its accessibility value is “Still to buy” or “Purchased”.
- The remove button is labelled for accessibility “Remove [item name]” and deletes that item.
- Checked items appear under “Purchased”. “Clear purchased items” removes them.
- An empty list shows “Nothing to pick up” and “Type an item above, or add one here when you use up a batch.”

### “Ledger”

“The past seven days” shows counts of “Used” and “Discarded” entries. “Shelf history” is marked “Archive”. The “Movements” control filters the history with “All”, “Used”, and “Waste”. Each entry shows the product, amount, action, and recorded date and time.

Before a movement is recorded, the screen shows “No movements yet” and “Open a batch on your shelf to record how much you used or discarded.”

### Apple Watch

The watch app has two pages:

- “IcePantryOrbit” shows “Use first” and up to five batches in printed-date order. If it has not received pantry data, it says “Open IcePantryOrbit on your iPhone to sync.” If the synced shelves are empty, it says “Your shelves are empty. Add a batch on iPhone.” “Refresh from iPhone” requests an update.
- “Market” shows “Check off purchases”. Tapping an item marks it purchased on the iPhone. An empty list says “Your shopping list is empty.” A pending change shows “Awaiting sync · [number]”.

### “Use first” widget

The small and medium widget is described as “See which pantry batches reach their printed dates first.” It shows “PANTRY ORBIT”, the earliest batch and its date and quantity; the medium version can also show “Next · [product] · [date]”. Tapping it opens that batch, or the shelves when empty. The empty widget says “An open shelf” and “Add your first batch in IcePantryOrbit.”

## Features

- “Shelves” with quantities, storage locations, printed dates, search, and date filtering.
- “Food catalog” search, barcode scanning, and “Enter label by hand”.
- “Record a movement” for “Use” or “Discard”, with an optional “Add to shopping list”.
- “Market list” with purchased items and Apple Watch check-off.
- “Ledger” with seven-day entry counts and “Shelf history”.
- “Use first” Apple Watch view and widget.

## Behaviours that can look like bugs

- “Add to shelf” and “Save changes” remain disabled until “Product name” is nonblank and “Quantity” is a whole number from 1 to 9,999,999.
- “Use this product” requires a nonblank “Product name”. Optional nutrition values must be valid nonnegative numbers: energy at most 1,000 and each gram value at most 100.
- “Search Open Food Facts” is disabled until the search has at least two characters and while a search is running. If there are no local matches, the screen says “No matches on this device. Search Open Food Facts or enter the details from the label.” An online search can show “No matches in Open Food Facts.”
- Catalog problems can show “This barcode isn’t in the catalog yet.”, “The catalog is limiting requests. Try again in a minute.”, “Couldn’t load the product data. Try again.”, or “Couldn’t reach the catalog. Use a saved product or enter the label by hand.” Try again, select a saved product, or use “Enter label by hand”.
- “Scanner unavailable” can explain “On this device, enter the digits printed under the barcode in the search field.”, “Camera access is unavailable. You can type the barcode in the search field.”, “The camera is busy. Try again later or enter the barcode by hand.”, or “Enter the digits printed under the barcode in the search field.” Use “Back to search”, or “Open Settings” when offered.
- “Record use” and “Record waste” are disabled unless the quantity is a whole number from 1 through the remaining batch quantity. “All” fills in the maximum. Recording the full quantity removes the batch from the shelves; the movement remains in “Ledger”.
- The market add button is disabled for a blank item or an item already waiting in “To pick up”, ignoring letter case. A purchased item can be added again.
- “To pick up”, “Purchased”, and “Shelf history” grow as items and movements are recorded. “Clear purchased items” removes checked-off items; individual items can also be removed.
- On Apple Watch, purchase buttons are disabled until the connection is active. “Awaiting sync · [number]” remains until the update is reflected in the list.
- The shelf, market, and ledger empty states disappear as the corresponding batches, shopping items, and movements are added.

## Starter content and resume

A fresh pantry, market list, and ledger are empty. The food catalog includes a selection of products available on the device before an online search; the widget preview may show “Tomatoes”.

Saved batches, shopping items, and ledger entries remain available when the app is reopened. An unsaved form is not presented as a resumable draft.

## Permissions

- Camera: requested when “Scan a barcode” is opened on a supported device. The usage description is “Scan a package barcode to find the product in Open Food Facts.”

## Absent

There is no login or account flow, in-app purchase, ads, analytics, account deletion flow, or App Tracking Transparency prompt. Users can create their own pantry batches, shopping items, and manual product entries; there is no visible flow for publishing them to other users.

## Data and support

Pantry batches, shopping items, and history are stored on the device and shared with the app’s widget and paired Apple Watch. Product searches and barcode lookups contact Open Food Facts, and product images may be loaded online.

There is no on-screen “Contact” or “Support” control.

## Scanning and health

The scanner accepts package barcodes and QR codes containing an 8–14 digit product code, then looks up that code in Open Food Facts. Users can also type barcode digits into “Name, brand or barcode”.

The manual product form accepts nutrition and ingredient information from a package, but the pantry and market screens do not display a nutrition or medical assessment. The catalog’s product-data attribution and “Open Food Facts · Data ODbL · Photos CC BY-SA” link appear at the bottom of “Food catalog”; a batch selected with a numeric barcode can also offer “View on Open Food Facts ↗”.

## Platform

The app uses English and US locale formatting regardless of the device’s region setting. It supports iPhone and iPad, with a minimum of iOS 17.0. iPhone supports portrait and both landscape orientations; iPad also supports upside-down portrait. The companion Apple Watch app requires watchOS 10.0 or later.

## Category

Food & Drink.
