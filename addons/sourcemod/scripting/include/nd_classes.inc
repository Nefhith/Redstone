/* Main and Subclass constants for the following prop ents
 * "m_iPlayerClass"
 * "m_iPlayerSubclass"
 * "m_iDesiredPlayerClass"
 * m_iDesiredPlayerSubclass"
 */
 
#define MAIN_CLASS_ASSAULT 	0
#define MAIN_CLASS_EXO 		1
#define MAIN_CLASS_STEALTH	2
#define	MAIN_CLASS_SUPPORT	3

#define ASSAULT_CLASS_INFANTRY	0
#define ASSAULT_CLASS_GRENADIER	1
#define	ASSAULT_CLASS_SNIPER	2

#define EXO_CLASS_SUPRESSION	0
#define EXO_CLASS_SEIGE_KIT		1

#define	STEALTH_CLASS_ASSASSIN	0
#define	STEALTH_CLASS_SNIPER	1
#define STEALTH_CLASS_SABATEUR 	2

#define SUPPORT_CLASS_MEDIC		0
#define SUPPORT_CLASS_ENGINEER	1
#define SUPPORT_CLASS_BBQ		2

/* Player class stock functions */
stock bool:IsSniperClass(class, subClass) 
{
	return 	   (class == MAIN_CLASS_ASSAULT && subClass == ASSAULT_CLASS_SNIPER) 
	        || (class == MAIN_CLASS_STEALTH && subClass == STEALTH_CLASS_SNIPER)
}
stock bool:IsStealthClass(class)
{
	return class == MAIN_CLASS_STEALTH;
}

/* Orginally for the damage fix plugin */
stock bool:IsExoSeigeKit(class, subClass)
{
	return class == MAIN_CLASS_EXO && subClass == EXO_CLASS_SEIGE_KIT;
}
stock bool:IsSupportBBQ(class, subClass)
{
	return class == MAIN_CLASS_SUPPORT && subClass == SUPPORT_CLASS_BBQ;
}
stock bool:IsStealthSab(class, subClass)
{
	return class == MAIN_CLASS_STEALTH && subClass == STEALTH_CLASS_SABATEUR;
}

stock ResetClass(client, mainClass, subClass, gizmo = -1)
{
	FakeClientCommand(client, "joinclass %d %d", mainClass, subClass);
	
	SetEntProp(client, Prop_Send, "m_iPlayerClass", mainClass);
    	SetEntProp(client, Prop_Send, "m_iPlayerSubclass", subClass);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", mainClass);
	SetEntProp(client, Prop_Send, "m_iDesiredPlayerSubclass", subClass);
	
	if (gizmo != -1)
		SetEntProp(client, Prop_Send, "m_iDesiredGizmo", gizmo);
}
