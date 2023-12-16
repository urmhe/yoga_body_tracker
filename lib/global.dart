import 'package:flutter/material.dart';

/// Contains some global widgets and constant values that are reused throughout the app

// Textstyle that is used for the Appbar
final TextStyle appBarTextStyle =  TextStyle(
  color: Colors.grey.shade800,
  fontFamily: 'Parisienne',
  fontSize: 37.0,
  fontWeight: FontWeight.bold
);

const Duration snackBarDuration = Duration(seconds: 3);

const Color backgroundColor = Colors.white;

// Radius used for most rounded containers in the app
const double regularBorderRadius = 15.0;
const double largeBorderRadius = 30.0;
const double veryLargeBorderRadius = 45.0;
const double smallBorderRadius = 8.0;

// Spacing values
const double largeSpacing = 8.0;
const double smallSpacing = 4.0;
const double veryLargeSpacing = 16.0;

// Route Strings
const String homeRoute = 'home';
const String scanRoute = 'scanPage';

