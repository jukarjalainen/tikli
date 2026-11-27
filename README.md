# Tikli – Bird Observation Tracker

Tikli (Finnish for Goldfinch) is a Flutter-based mobile application designed for bird enthusiasts to record, track, and visualize their sightings. The app focuses on localized Finnish bird species and provides a seamless workflow from observation to data export.

## Key Features

- Fast Species Selection: Users can choose from a curated list of common Finnish bird species without havin to type anything. A manual entry option is available for rare sightings.
- Observations are categorized into three specific types
   - Vuodenpinna (Yearly)
   - Oma lista (Custom)
   - Elämänpinna (Life)

- Geolocation Integration: Automatically fetches the user's current location and timestamp for each entry
- Interactive Map: All saved observations are pinned on a dynamic map for visual tracking
- Comprehensive History: View and manage all past observations in categorized lists.
- Data Portability: Export your entire observation history as a text file for external use.

- https://github.com/user-attachments/assets/0dfa7d91-2603-4d8f-8d35-95fd74af5301
  
### Tech stack
- State Management: flutter_bloc (v9.0.0) for a predictable and scalable architecture.
- Local Database: sqflite (v2.4.2) for persistent on-device storage of bird sightings.
- Mapping: flutter_map (v7.0.2) and latlong2 for geographic visualizations.
- Geolocation: geolocator (v10.1.0) for real-time coordinate retrieval.
- Routing: Modular routing system implemented in AppRouter.
- Sharing: share_plus (v12.0.1) for exporting observation data.

### Architecture & Services
The application follows a clean feature-based architecture to separate concerns:
- Features: Modular folders for observation_form, observation_list, observation_map, and species_list.
- Database Service: A dedicated DatabaseService class manages SQLite initialization and CRUD operations for the observations table.
- Core Logic: Uses Enums and Extensions (e.g., ObservationType) to ensure type safety and clean storage keys.

Developed by Juhani Karjalainen
