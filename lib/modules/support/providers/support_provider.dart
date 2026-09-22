import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/ticket_response.dart';
import '../models/support_category.dart';
import '../services/support_service.dart';

class SupportProvider extends ChangeNotifier {
  final SupportService _service = SupportService();

  List<SupportTicket> _tickets = [];
  List<SupportTicket> _openTickets = [];
  SupportTicket? _selectedTicket;
  List<TicketResponse> _responses = [];
  List<SupportCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<SupportTicket> get tickets => _tickets;
  List<SupportTicket> get openTickets => _openTickets;
  SupportTicket? get selectedTicket => _selectedTicket;
  List<TicketResponse> get responses => _responses;
  List<SupportCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedTicketForTest(SupportTicket? value) => _selectedTicket = value;

  Future<void> loadTickets({
    String? patientId,
    String? assignedTo,
    String? status,
    String? priority,
    bool? isOpen,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tickets = await _service.getTickets(
        patientId: patientId,
        assignedTo: assignedTo,
        status: status,
        priority: priority,
        isOpen: isOpen,
      );
      if (isOpen == null && patientId != null) {
        // Also load open tickets for badge count
        _openTickets = await _service.getTickets(
          patientId: patientId,
          isOpen: true,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTicket(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedTicket = await _service.getTicket(id);
      if (_selectedTicket != null) {
        await _loadResponses(id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTicket(SupportTicket ticket) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.createTicket(ticket);
      _tickets.insert(0, saved);
      _selectedTicket = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTicket(SupportTicket ticket) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updateTicket(ticket);
      final index = _tickets.indexWhere((t) => t.id == saved.id);
      if (index != -1) _tickets[index] = saved;
      if (_selectedTicket?.id == saved.id) _selectedTicket = saved;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTicketStatus(
    String id,
    String newStatus, {
    String? resolutionNote,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateTicketStatus(
        id,
        newStatus,
        resolutionNote: resolutionNote,
      );
      final index = _tickets.indexWhere((t) => t.id == id);
      if (index != -1) _tickets[index] = updated;
      if (_selectedTicket?.id == id) _selectedTicket = updated;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTicket(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteTicket(id);
      _tickets.removeWhere((t) => t.id == id);
      if (_selectedTicket?.id == id) _selectedTicket = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadResponses(String ticketId) async {
    try {
      _responses = await _service.getResponsesForTicket(ticketId);
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> addResponse(TicketResponse response) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.addResponse(response);
      _responses.add(saved);
      // Reload ticket to update response count
      if (_selectedTicket != null) {
        _selectedTicket = await _service.getTicket(_selectedTicket!.id);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitFeedback({
    required String ticketId,
    required String patientId,
    required int rating,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submitFeedback(
        ticketId: ticketId,
        patientId: patientId,
        rating: rating,
        comment: comment,
      );
      // Reload ticket to update feedback status
      if (_selectedTicket?.id == ticketId) {
        _selectedTicket = await _service.getTicket(ticketId);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  int get openTicketsCount => _openTickets.length;

  void clearSelected() {
    _selectedTicket = null;
    _responses = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
