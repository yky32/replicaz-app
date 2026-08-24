import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';

/// Type scale (Uber Base–style roles, Replicaz faces).
/// Syne needs ≥ ~1.25 height or g/y/p descenders clip on iOS.
abstract final class AppType {
  static TextStyle display(BuildContext context, {Color? color}) =>
      GoogleFonts.syne(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.28,
        color: color ?? AppColors.ink,
      );

  static TextStyle titleLg({Color? color}) => GoogleFonts.syne(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.28,
        color: color ?? AppColors.ink,
      );

  static TextStyle titleMd({Color? color}) => GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.28,
        color: color ?? AppColors.ink,
      );

  static TextStyle titleSm({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        height: 1.3,
        color: color ?? AppColors.ink,
      );

  static TextStyle labelLg({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color ?? AppColors.ink,
      );

  static TextStyle labelMd({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color ?? AppColors.inkSoft,
      );

  static TextStyle labelSm({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        height: 1.3,
        color: color ?? AppColors.inkMuted,
      );

  static TextStyle body({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: color ?? AppColors.ink,
      );

  static TextStyle bodySm({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color ?? AppColors.inkMuted,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: color ?? AppColors.inkMuted,
      );

  static TextStyle overline({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        height: 1.25,
        color: color ?? AppColors.inkMuted,
      );
}
