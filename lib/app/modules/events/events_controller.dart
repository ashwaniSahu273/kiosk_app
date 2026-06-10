import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../home/section_state.dart';

class EventsController extends GetxController {
  EventsController();

  final Rx<SectionState<List<Event>>> events =
      Rx<SectionState<List<Event>>>(const SectionLoading<List<Event>>());

  final Rxn<Event> detailEvent = Rxn<Event>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (_retained() == null) {
      events.value = const SectionLoading<List<Event>>();
    }

    // Demo data
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final List<Event> items = _demoEvents();

    events.value = items.isEmpty
        ? const SectionEmpty<List<Event>>()
        : SectionLoaded<List<Event>>(items);
  }

  void openEventDetail(Event event) {
    detailEvent.value = event;
  }

  void clearDetail() {
    detailEvent.value = null;
  }

  List<Event>? _retained() {
    final SectionState<List<Event>> state = events.value;
    if (state is SectionLoaded<List<Event>>) {
      return state.data;
    }
    if (state is SectionError<List<Event>>) {
      return state.previousData;
    }
    return null;
  }

  static List<Event> _demoEvents() {
    return <Event>[
      const Event(
        organizationId: 'demo',
        id: 'evt-1',
        name: 'Friday Jumu\'ah Prayer',
        description:
            'Weekly Friday congregational prayer. Khutbah begins at 1:15 PM followed by Salah. All community members are welcome to attend.',
        date: 'Every Friday',
        time: '1:15 PM',
        location: 'Main prayer hall',
      ),
      const Event(
        organizationId: 'demo',
        id: 'evt-2',
        name: 'Quran Study Circle',
        description:
            'Weekly Quran study and reflection session. We explore the meanings and teachings of the Quran in a small group setting. Open to all levels.',
        date: 'Every Wednesday',
        time: '7:30 PM',
        location: 'Community room B',
      ),
      const Event(
        organizationId: 'demo',
        id: 'evt-3',
        name: 'Community Iftar Dinner',
        description:
            'Join the community for a blessed iftar dinner during Ramadan. Bring a dish to share and break your fast with friends and family.',
        date: 'Ramadan 2025',
        time: 'Maghrib time',
        location: 'Community hall',
      ),
      const Event(
        organizationId: 'demo',
        id: 'evt-4',
        name: 'Youth Leadership Workshop',
        description:
            'A workshop for young Muslims aged 13-18 focusing on leadership skills, public speaking, and community engagement.',
        date: 'Saturday, March 15',
        time: '10:00 AM - 4:00 PM',
        location: 'Youth center',
      ),
      const Event(
        organizationId: 'demo',
        id: 'evt-5',
        name: 'Islamic Lecture Series',
        description:
            'Monthly guest speaker series covering topics of Islamic spirituality, contemporary issues, and personal development.',
        date: 'Last Saturday monthly',
        time: '6:30 PM',
        location: 'Main prayer hall',
      ),
    ];
  }
}
