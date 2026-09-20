import 'package:flutter/material.dart';
import '../models/pharmacy_group.dart';
import '../models/group_member.dart';
import '../models/stock_transfer.dart';
import '../services/chain_service.dart';

class ChainProvider extends ChangeNotifier {
  final ChainService _service = ChainService();

  List<PharmacyGroup> _groups = [];
  PharmacyGroup? _selectedGroup;
  List<GroupMember> _members = [];
  List<StockTransfer> _transfers = [];
  StockTransfer? _selectedTransfer;
  bool _isLoading = false;
  String? _error;

  List<PharmacyGroup> get groups => _groups;
  PharmacyGroup? get selectedGroup => _selectedGroup;
  List<GroupMember> get members => _members;
  List<StockTransfer> get transfers => _transfers;
  StockTransfer? get selectedTransfer => _selectedTransfer;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @visibleForTesting
  set errorForTest(String? value) => _error = value;

  @visibleForTesting
  set selectedGroupForTest(PharmacyGroup? value) => _selectedGroup = value;

  // ---- Groups ----

  Future<void> loadGroups({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _groups = await _service.getGroups(isActive: isActive);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadGroup(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedGroup = await _service.getGroup(id);
      if (_selectedGroup != null) {
        await loadMembers(_selectedGroup!.id);
        await loadTransfers(groupId: _selectedGroup!.id);
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveGroup(PharmacyGroup group) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      PharmacyGroup saved;
      if (group.id.isEmpty || group.id.startsWith('temp_')) {
        saved = await _service.createGroup(group);
        _groups.insert(0, saved);
      } else {
        saved = await _service.updateGroup(group);
        final index = _groups.indexWhere((g) => g.id == saved.id);
        if (index != -1) _groups[index] = saved;
      }
      _selectedGroup = saved;
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

  Future<bool> deleteGroup(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteGroup(id);
      _groups.removeWhere((g) => g.id == id);
      if (_selectedGroup?.id == id) _selectedGroup = null;
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

  // ---- Members ----

  Future<void> loadMembers(String groupId) async {
    try {
      _members = await _service.getGroupMembers(groupId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> addMember(GroupMember member) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.addMember(member);
      _members.add(saved);
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

  Future<bool> updateMember(GroupMember member) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _service.updateMember(member);
      final index = _members.indexWhere((m) => m.id == saved.id);
      if (index != -1) _members[index] = saved;
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

  Future<bool> removeMember(String memberId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.removeMember(memberId);
      _members.removeWhere((m) => m.id == memberId);
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

  // ---- Transfers ----

  Future<void> loadTransfers({
    String? groupId,
    String? fromPharmacyId,
    String? toPharmacyId,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _transfers = await _service.getTransfers(
        groupId: groupId,
        fromPharmacyId: fromPharmacyId,
        toPharmacyId: toPharmacyId,
        status: status,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTransfer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedTransfer = await _service.getTransfer(id);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveTransfer(StockTransfer transfer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      StockTransfer saved;
      final isCreate = transfer.id.isEmpty || transfer.id.startsWith('temp_');
      if (isCreate) {
        saved = await _service.createTransfer(transfer);
        _transfers.insert(0, saved);
      } else {
        saved = await _service.updateTransfer(transfer);
        final index = _transfers.indexWhere((t) => t.id == saved.id);
        if (index != -1) _transfers[index] = saved;
      }
      // Audit Module 26 (CHN), Étape 3 (05/09/2026) — CHN-11 : les articles
      // saisis dans `TransferCreateScreen` (`transfer.items`) n'étaient
      // jamais persistés — ni `ChainService.createTransfer()` ni ce
      // provider n'appelaient `addTransferItem()`, si bien qu'un transfert
      // était créé sans jamais aucun article associé en base, quelle que
      // soit la saisie utilisateur. Défaut découvert en câblant CHN-7
      // (lot/péremption réels) — même motif de câblage manquant que C105
      // (Module 22/FAM), pas une lacune socle.
      if (isCreate && transfer.items != null && transfer.items!.isNotEmpty) {
        final addedItems = <TransferItem>[];
        for (final item in transfer.items!) {
          final addedItem = await _service.addTransferItem(
            item.copyWith(transferId: saved.id),
          );
          addedItems.add(addedItem);
        }
        saved = saved.copyWith(items: addedItems);
        final index = _transfers.indexWhere((t) => t.id == saved.id);
        if (index != -1) _transfers[index] = saved;
      }
      _selectedTransfer = saved;
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

  Future<bool> updateTransferStatus(
    String id,
    String newStatus, {
    DateTime? receivedDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateTransferStatus(
        id,
        newStatus,
        receivedDate: receivedDate,
      );
      final index = _transfers.indexWhere((t) => t.id == id);
      if (index != -1) _transfers[index] = updated;
      if (_selectedTransfer?.id == id) _selectedTransfer = updated;
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

  Future<bool> deleteTransfer(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteTransfer(id);
      _transfers.removeWhere((t) => t.id == id);
      if (_selectedTransfer?.id == id) _selectedTransfer = null;
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

  void clearSelected() {
    _selectedGroup = null;
    _selectedTransfer = null;
    _members = [];
    _transfers = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
