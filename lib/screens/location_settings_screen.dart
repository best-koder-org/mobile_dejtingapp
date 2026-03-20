import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _isLoading = false;
  bool _permissionGranted = false;
  Position? _lastPosition;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final permission = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _permissionGranted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      });
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (position != null) {
        final success =
            await LocationService.instance.updateBackendLocation();
        if (mounted) {
          setState(() {
            _lastPosition = position;
            _isLoading = false;
            if (!success) {
              _errorMessage = 'Could not sync location with server';
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Could not get current location';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  Future<void> _requestPermission() async {
    final permission = await Geolocator.requestPermission();
    if (mounted) {
      setState(() {
        _permissionGranted = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      });
      if (_permissionGranted) {
        _refreshLocation();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationSettings),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          // Permission status
          ListTile(
            leading: Icon(
              _permissionGranted ? Icons.check_circle : Icons.location_off,
              color: _permissionGranted ? Colors.green : Colors.grey,
            ),
            title: Text(l10n.enableLocation),
            subtitle: Text(
              _permissionGranted ? 'Permission granted' : 'Permission required',
            ),
            trailing: _permissionGranted
                ? null
                : TextButton(
                    onPressed: _requestPermission,
                    child: Text(l10n.enableLocationBtn),
                  ),
          ),
          const Divider(),
          // Current location
          ListTile(
            leading: const Icon(Icons.my_location, color: AppTheme.primaryColor),
            title: Text(l10n.locationLabel),
            subtitle: _lastPosition != null
                ? Text(
                    '${_lastPosition!.latitude.toStringAsFixed(4)}, '
                    '${_lastPosition!.longitude.toStringAsFixed(4)}',
                  )
                : Text(l10n.locationSubtitle),
            trailing: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _permissionGranted ? _refreshLocation : null,
                  ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Divider(),
          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.locationDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
