import 'package:lifeos/services/pray_times.dart';

enum RuleCategory { lifeCharacter, islamic }
enum RuleSubCategory {
  family,society,money,health,discipline,phoneInternet,personalGrowth,
  salah,dhikr,sadaqah,quran,dua,goodDeeds,character,avoidBadHabits
}
enum RuleFrequencyType { daily, weekly, monthly, custom }
enum RuleVerification { selfCheck }
enum RecoveryType { custom, none }
enum SadaqahStatus { pledged, given, missed, pending, closed }
enum RuleStatus { pending, completed, missed, skipped, notApplicable }

class RuleFrequency {
  final RuleFrequencyType type;
  final int? daysOfWeek, dayOfMonth, intervalDays;
  const RuleFrequency({required this.type, this.daysOfWeek, this.dayOfMonth, this.intervalDays});
  Map<String,dynamic> toMap()=>{'type':type.name,'daysOfWeek':daysOfWeek,'dayOfMonth':dayOfMonth,'intervalDays':intervalDays};
  factory RuleFrequency.fromMap(Map<dynamic,dynamic>? m){
    if(m==null)return const RuleFrequency(type:RuleFrequencyType.daily);
    RuleFrequencyType t=RuleFrequencyType.daily;
    switch(m['type']){case 'weekly':t=RuleFrequencyType.weekly;break;case 'monthly':t=RuleFrequencyType.monthly;break;case 'custom':t=RuleFrequencyType.custom;break;default:t=RuleFrequencyType.daily;}
    return RuleFrequency(type:t,daysOfWeek:(m['daysOfWeek'] as num?)?.toInt(),dayOfMonth:(m['dayOfMonth'] as num?)?.toInt(),intervalDays:(m['intervalDays'] as num?)?.toInt());
  }
}
class RuleTarget{final num value;final String unit;const RuleTarget({required this.value,this.unit='count'});Map<String,dynamic> toMap()=>{'value':value,'unit':unit};factory RuleTarget.fromMap(Map<dynamic,dynamic>? m){if(m==null)return const RuleTarget(value:1);return RuleTarget(value:(m['value'] as num?)??1,unit:(m['unit'] as String?)??'count');}}
class RuleReminder{final bool enabled;final int hour,minute;final bool repeatDaily;const RuleReminder({this.enabled=false,this.hour=21,this.minute=0,this.repeatDaily=true});Map<String,dynamic> toMap()=>{'enabled':enabled,'hour':hour,'minute':minute,'repeatDaily':repeatDaily};factory RuleReminder.fromMap(Map<dynamic,dynamic>? m){if(m==null)return const RuleReminder();return RuleReminder(enabled:m['enabled']==true,hour:((m['hour'] as num?)??21).toInt(),minute:((m['minute'] as num?)??0).toInt(),repeatDaily:m['repeatDaily']!=false);}}
class RuleRecoveryAction{final RecoveryType type;final String? customText;const RuleRecoveryAction({this.type=RecoveryType.none,this.customText});Map<String,dynamic> toMap()=>{'type':type.name,'customText':customText};factory RuleRecoveryAction.fromMap(Map<dynamic,dynamic>? m){if(m==null)return const RuleRecoveryAction();RecoveryType t=RecoveryType.none;switch(m['type']){case 'custom':t=RecoveryType.custom;break;default:t=RecoveryType.none;}return RuleRecoveryAction(type:t,customText:m['customText'] as String?);}}
class RulePeriod{final String type;final int? dayOfWeek,dayOfMonth;const RulePeriod({this.type='daily',this.dayOfWeek,this.dayOfMonth});Map<String,dynamic> toMap()=>{'type':type,'dayOfWeek':dayOfWeek,'dayOfMonth':dayOfMonth};factory RulePeriod.fromMap(Map<dynamic,dynamic>? m){if(m==null)return const RulePeriod();return RulePeriod(type:(m['type'] as String?)??'daily',dayOfWeek:(m['dayOfWeek'] as num?)?.toInt(),dayOfMonth:(m['dayOfMonth'] as num?)?.toInt());}}
class RulePeriodEndReminder{final bool enabled;final int daysBeforeEnd,hour,minute;const RulePeriodEndReminder({this.enabled=false,this.daysBeforeEnd=1,this.hour=21,this.minute=0});Map<String,dynamic> toMap()=>{'enabled':enabled,'daysBeforeEnd':daysBeforeEnd,'hour':hour,'minute':minute};factory RulePeriodEndReminder.fromMap(Map<dynamic,dynamic>? m){if(m==null)return const RulePeriodEndReminder();return RulePeriodEndReminder(enabled:m['enabled']==true,daysBeforeEnd:((m['daysBeforeEnd'] as num?)??1).toInt(),hour:((m['hour'] as num?)??21).toInt(),minute:((m['minute'] as num?)??0).toInt());}}
class RuleSource{final String type;final String? reference,authenticity;const RuleSource({this.type='personal',this.reference,this.authenticity});Map<String,dynamic> toMap()=>{'type':type,'reference':reference,'authenticity':authenticity};factory RuleSource.fromMap(Map<dynamic,dynamic>? m){if(m==null)return const RuleSource();return RuleSource(type:(m['type'] as String?)??'personal',reference:m['reference'] as String?,authenticity:m['authenticity'] as String?);}}
