# Refrigerator IoT System

A modern Flutter application for monitoring and controlling IoT-enabled refrigerators. This system provides real-time temperature monitoring, fan speed control, and connectivity status tracking to ensure optimal refrigeration performance.

## Features

### Real-time Monitoring
- **Temperature Tracking**: Live temperature readings with color-coded indicators
- **Temperature Status**: Automatic status updates (Too Cold, Cold, Optimal, Warm, Too Hot)
- **Visual Gauge**: Interactive radial gauge displaying temperature from -20°C to 40°C
- **Color-coded Indicators**: 
  - Blue: Below 0°C
  - Green: 0°C to 20°C
  - Red: Above 20°C

### Fan Control
- **Dynamic Fan Speed Control**: Adjustable fan speed from 0 to 255
- **Real-time Updates**: Instant fan speed adjustments
- **Visual Feedback**: Clear display of current fan speed settings

### Connectivity Features
- **Live Connection Status**: Real-time monitoring of internet connectivity
- **Visual Indicators**: 
  - Green status for online connection
  - Red status for offline connection
- **Auto-detection**: Automatic detection of WiFi, mobile, and ethernet connections

### Authentication
- **Secure Login**: Email and password authentication
- **User Registration**: New user signup functionality
- **Persistent Sessions**: Remember user login state
- **Error Handling**: Comprehensive error messages for authentication issues

### UI/UX
- **Modern Design**: Material Design 3 implementation
- **Responsive Layout**: Adapts to different screen sizes
- **Intuitive Controls**: Easy-to-use sliders and buttons
- **Visual Feedback**: Clear status indicators and loading states

## Technical Stack

- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Firebase Realtime Database
- **State Management**: Native Flutter State Management
- **Connectivity**: connectivity_plus package
- **Charts**: syncfusion_flutter_gauges

## Getting Started

### Prerequisites
- Flutter SDK (>=3.1.3)
- Firebase account
- Android Studio / VS Code with Flutter plugins

### Installation

1. Clone the repository:
```bash
git clone [repository-url]
cd refrigerator_iot_system
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
- Create a new Firebase project
- Add Android/iOS apps in Firebase console
- Download and add configuration files
- Enable Authentication and Realtime Database

4. Run the application:
```bash
flutter run
```

## Configuration

### Firebase Setup
1. Enable Email/Password authentication in Firebase Console
2. Set up Realtime Database with the following structure:
```json
{
  "tempData": 0.0,
  "fanSpeed": 0
}
```

### Environment Variables
No environment variables are required as Firebase configuration is included in the project files.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the Setsom License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase for the backend infrastructure
- Syncfusion for the gauge widgets
- connectivity_plus team for network status management
