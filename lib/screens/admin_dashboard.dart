import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService api = ApiService();
  List members = [];
  bool loading = false;
  String filter = "Pending";

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(()=>loading=true);
    final r = await api.fetchMembers(status: filter);
    setState(()=>loading=false);
    if (r['status']==1 || r['status']=="1") {
      setState(()=>members = r['members'] ?? []);
    } else {
      setState(()=>members = []);
    }
  }

  void openExport(String type) async {
    final url = AppConstants.baseUrl + AppConstants.exportMembers + "?type=$type&status=$filter";
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("Admin Dashboard"), actions: [
          PopupMenuButton<String>(onSelected: (v){ filter = v; fetch(); }, itemBuilder: (_)=>[
            const PopupMenuItem(value: "Pending", child: Text("Pending")),
            const PopupMenuItem(value: "Approved", child: Text("Approved")),
            const PopupMenuItem(value: "Rejected", child: Text("Rejected")),
            const PopupMenuItem(value: "", child: Text("All")),
          ])
        ]),
        body: loading ? const Center(child:CircularProgressIndicator()) : Column(children:[
          Row(children:[
            ElevatedButton(onPressed: ()=>openExport('excel'), child: const Text("Export Excel")),
            const SizedBox(width:8),
            ElevatedButton(onPressed: ()=>openExport('pdf'), child: const Text("Export PDF")),
          ]),
          Expanded(child: ListView.builder(itemCount: members.length, itemBuilder: (c,i){
            final m = members[i];
            return ListTile(
              leading: m['photo'] != null ? Image.network("${AppConstants.uploadsPublic}${m['photo']}", width:50, height:50, fit:BoxFit.cover) : null,
              title: Text(m['name'] ?? "—"),
              subtitle: Text("CNIC: ${m['cnic'] ?? '—'}"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children:[
                IconButton(icon: const Icon(Icons.check, color:Colors.green), onPressed: () async { await api.updateMemberStatus(m['id'], 'Approved'); fetch(); }),
                IconButton(icon: const Icon(Icons.close, color:Colors.red), onPressed: () async { await api.updateMemberStatus(m['id'], 'Rejected'); fetch(); }),
              ]),
              onTap: () {
                // open download link
                final url = AppConstants.baseUrl + "admin/download_member.php?id=${m['id']}";
                launchUrl(Uri.parse(url));
              },
            );
          }))
        ]),
      ),
    );
  }
}
