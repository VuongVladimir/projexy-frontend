import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/common/constants/global_variables.dart';
import 'package:frontend/common/constants/http_handling.dart';
import 'package:frontend/common/constants/utils.dart';
import 'package:frontend/models/dependency.dart';

class DependencyService {
  // Tạo dependency
  static Future<void> createDependency({
    required BuildContext context,
    required String predecessorId,
    required String successorId,
    required String projectId,
    required Function(Dependency, DependencyViolation?) onSuccess,
  }) async {
    try {
      final body = {
        'predecessorId': predecessorId,
        'successorId': successorId,
        'projectId': projectId,
      };
      
      final response = await ApiClient.post(
        url: '$uri/api/dependency/create',
        body: json.encode(body),
      );
      
      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final dependency = Dependency.fromMap(data['dependency']);
            final violation = data['violation'] != null
                ? DependencyViolation.fromMap(data['violation'])
                : null;
            onSuccess(dependency, violation);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }
  
  // Xóa dependency
  static Future<void> deleteDependency({
    required BuildContext context,
    required String dependencyId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await ApiClient.delete(
        url: '$uri/api/dependency/$dependencyId',
      );
      
      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: onSuccess,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }
  
  // Lấy dependencies của task
  static Future<void> getTaskDependencies({
    required BuildContext context,
    required String taskId,
    required Function(List<Dependency> predecessors, List<Dependency> successors) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/dependencies',
      );
      
      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final predecessors = List<Dependency>.from(
              (data['predecessors'] as List? ?? []).map((d) => Dependency.fromMap(d))
            );
            final successors = List<Dependency>.from(
              (data['successors'] as List? ?? []).map((d) => Dependency.fromMap(d))
            );
            onSuccess(predecessors, successors);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }
  
  // Lấy violations của task
  static Future<void> getTaskViolations({
    required BuildContext context,
    required String taskId,
    required Function(DependencyViolation?) onSuccess,
  }) async {
    try {
      final response = await ApiClient.get(
        url: '$uri/api/task/$taskId/violations',
      );
      
      if (context.mounted) {
        httpResponseHandle(
          response: response,
          context: context,
          onSuccess: () {
            final data = json.decode(response.body);
            final violation = data['violation'] != null
                ? DependencyViolation.fromMap(data['violation'])
                : null;
            onSuccess(violation);
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackBar(context, 'Lỗi: ${e.toString()}');
      }
    }
  }
}
