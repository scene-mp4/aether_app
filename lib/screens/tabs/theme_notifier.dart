import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> initializeTheme() async {
	final preferences = await SharedPreferences.getInstance();
	themeNotifier.value = preferences.getBool('darkMode') == true
			? ThemeMode.dark
			: ThemeMode.light;
}

Future<void> setDarkMode(bool enabled) async {
	themeNotifier.value = enabled ? ThemeMode.dark : ThemeMode.light;
	final preferences = await SharedPreferences.getInstance();
	await preferences.setBool('darkMode', enabled);
}