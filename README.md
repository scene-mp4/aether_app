# Pollutracker

**Project Title:** PolluTracker: An IoT Air Pollution Monitoring Device with GPS Tracker and Mobile Application Integration

**Description**: Pollutracker is an IoT-based air pollution monitoring device that measures PM2.5 and CO₂, CO, and other combustible gas levels using air quality sensors and tracks its location through GPS. 
The device transmits real-time pollution and location data via WiFi to a mobile application, where users can view deployed trackers on an interactive map. It enables LGUs, researchers, and citizens to monitor air quality across multiple areas and identify locations that need environmental improvement.

**Technologies Used**: Flutter, Dart, IoT, Visual Studio Code, Arduino IDE, MySQL Database, Github, Git

**Features**:
- Air quality monitoring for PM2.5 and CO₂ levels
- GPS-based location tracking of each Pollutracker device
- Cloud-based data transmission using ESP8266 WiFi connectivity
- Mobile application integration for easy access to data
- Data visualization for pollution trends and statistics
- Allows users to monitor and compare air quality across multiple areas
- Enables LGUs and researchers to identify pollution hotspots

**Installation Instructions**:
1. Software Installation
   1.1 Arduino IDE
     1.1.1 Download and install Arduino IDE
     1.1.2 Add ESP8266 support:
           - Go to File → Preferences
           - Paste ESP8266 Board Manager URL
           - Open Tools → Board → Board Manager
           - Install ESP8266 by Espressif Systems
     1.1.3 Install required Arduino libraries:
           - ESP8266WiFi
           - TinyGPS++
           - PM2.5 sensor library (based on sensor used)
           - MQ gas sensor library
           - HTTPClient or MQTT library

   1.2 Flutter & Mobile App
     1.2.1 Install Flutter SDK
     1.2.2 Install Visual Studio Code
     1.2.3 Add extensions:
           - Flutter
           - Dart
     1.2.4 Clone the project repository
           - git clone <repository-url>
     1.2.5 Install dependencies:
           - flutter pub get

   1.3 Database & Backend
     1.3.1 Install MySQL
     1.3.2 Create the required database and tables for:
           - Devices
           - Sensor data
           - GPS coordinates
           - Timestamps
     1.3.3 Deploy backend API (local or cloud server)

**Setup**: 
1. Hardware Setup
- Components Required
       - ESP8266 (NodeMCU)
          - PM2.5 sensor
             - CO₂ / CO / combustible gas sensor
                - GPS module (NEO-6M or equivalent)
                   - Power source
                      - Jumper wires and enclosure
   
- Connections
       - Connect sensors to the ESP8266 following their datasheets
          - GPS module connected via UART (TX ↔ RX)
             - Ensure common ground across all components
                - Power the system via USB or battery

2. Firmware Setup
Open the PolluTracker firmware in Arduino IDE  
Configure the following:
       - WiFi SSID and password
          - Backend server/API endpoint
             - Unique device ID
                - Sensor calibration values
   
Select correct board and port:
   - Board: NodeMCU 1.0 (ESP8266)
      - Baud rate: 9600 or as required
       
Upload the code to the ESP8266
Monitor output using Serial Monitor

3. Mobile Application Setup
Open the Flutter project in VS Code
Configure:
- Backend API URL
   - Map API key
- Run the application:
  - flutter run
   
4. Deployment Setup
- Place PolluTracker devices in target areas
- Ensure stable WiFi connectivity
- Secure devices in weatherproof enclosures
- Begin air quality monitoring

