Function_LoadOpponentTrainerAndPokemons: ; 1f8000
	ld a, [rSVBK]
	push af
	ld a, BANK(wBT_OTTrainer)
	ld [rSVBK], a

	; Fill wBT_OTTrainer with zeros
	xor a
	ld hl, wBT_OTTrainer
	ld bc, wBT_OTTrainerEnd - wBT_OTTrainer
	call ByteFill

	; Write $ff into the Item-Slots
	ld a, $ff
	ld [wBT_OTPkmn1Item], a
	ld [wBT_OTPkmn2Item], a
	ld [wBT_OTPkmn3Item], a

	; Set wBT_OTTrainer as start address to write the following data to
	ld de, wBT_OTTrainer

	ld a, [hRandomAdd]
	ld b, a
.resample ; loop to find a random trainer
	call Random
	ld a, [hRandomAdd]
	add b
	ld b, a ; b contains the nr of the trainer
if DEF(_CRYSTAL11)
	maskbits BATTLETOWER_NUM_UNIQUE_TRAINERS
	cp BATTLETOWER_NUM_UNIQUE_TRAINERS
else
; Crystal 1.0 used the wrong constant here, so only the first 21
; trainers in BattleTowerTrainers can be sampled.
	maskbits BATTLETOWER_NUM_UNIQUE_PKMN
	cp BATTLETOWER_NUM_UNIQUE_PKMN
endc
	jr nc, .resample
	ld b, a

	ld a, BANK(sBTTrainers)
	call GetSRAMBank

	ld c, BATTLETOWER_STREAK_LENGTH
	ld hl, sBTTrainers
.next_trainer
	ld a, [hli]
	cp b
	jr z, .resample
	dec c
	jr nz, .next_trainer ; c <= 7  initialise all 7 trainers?

	ld hl, sBTTrainers
	ld a, [sNrOfBeatenBattleTowerTrainers]
	ld c, a
	ld a, b
	ld b, 0
	add hl, bc
	ld [hl], a

	call CloseSRAM

	push af
; Copy name (10 bytes) and class (1 byte) of trainer
	ld hl, BattleTowerTrainers
	ld bc, NAME_LENGTH
	call AddNTimes
	ld bc, NAME_LENGTH
	call CopyBytes

	call Function_LoadRandomBattleTowerPkmn
	pop af

	ld hl, BattleTowerTrainerData
	ld bc, BATTLETOWER_TRAINERDATALENGTH
	call AddNTimes
	ld bc, BATTLETOWER_TRAINERDATALENGTH
.copy_bt_trainer_data_loop
	ld a, BANK(BattleTowerTrainerData)
	call GetFarByte
	ld [de], a
	inc hl
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .copy_bt_trainer_data_loop

	pop af
	ld [rSVBK], a

	ret


Function_LoadRandomBattleTowerPkmn: ; 1f8081
	ld c, BATTLETOWER_PARTY_LENGTH
.loop
	push bc
	ld a, BANK(sBTPkmnPrevTrainer1)
	call GetSRAMBank

.FindARandomBattleTowerPkmn:
	; From Which LevelGroup are the Pkmn loaded
	; a = 1..10
	ld a, [wBTChoiceOfLvlGroup]
	dec a
	ld hl, BattleTowerMons
	ld bc, BattleTowerMons2 - BattleTowerMons1
	call AddNTimes

	ld a, [hRandomAdd]
	ld b, a
.resample
	call Random
	ld a, [hRandomAdd]
	add b
	ld b, a
	maskbits BATTLETOWER_NUM_UNIQUE_PKMN
	cp BATTLETOWER_NUM_UNIQUE_PKMN
	jr nc, .resample
	; in register 'a' is the chosen Pkmn of the LevelGroup

	; Check if Pkmn was already loaded before
	; Check current and the 2 previous teams
	; includes check if item is double at the current team
	ld bc, PARTYMON_STRUCT_LENGTH + MON_NAME_LENGTH
	call AddNTimes
	ld a, [hli]
	ld b, a
	ld a, [hld]
	ld c, a
	ld a, [wBT_OTPkmn1]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [wBT_OTPkmn1Item]
	cp c
	jr z, .FindARandomBattleTowerPkmn
	ld a, [wBT_OTPkmn2]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [wBT_OTPkmn2Item]
	cp c
	jr z, .FindARandomBattleTowerPkmn
	ld a, [wBT_OTPkmn3]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [wBT_OTPkmn3Item]
	cp c
	jr z, .FindARandomBattleTowerPkmn
	ld a, [sBTPkmnPrevTrainer1]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [sBTPkmnPrevTrainer2]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [sBTPkmnPrevTrainer3]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [sBTPkmnPrevPrevTrainer1]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [sBTPkmnPrevPrevTrainer2]
	cp b
	jr z, .FindARandomBattleTowerPkmn
	ld a, [sBTPkmnPrevPrevTrainer3]
	cp b
	jr z, .FindARandomBattleTowerPkmn

	ld bc, PARTYMON_STRUCT_LENGTH + MON_NAME_LENGTH
	call CopyBytes

	ld a, [wNamedObjectIndexBuffer]
	push af
	push de
	ld hl, - (PARTYMON_STRUCT_LENGTH + MON_NAME_LENGTH)
	add hl, de
	ld a, [hl]
	ld [wNamedObjectIndexBuffer], a
	ld bc, PARTYMON_STRUCT_LENGTH
	add hl, bc
	push hl
	call GetPokemonName
	ld h, d
	ld l, e
	pop de
	ld bc, MON_NAME_LENGTH
	call CopyBytes

	pop de
	pop af
	ld [wNamedObjectIndexBuffer], a
	pop bc
	dec c
	jp nz, .loop

	ld a, [sBTPkmnPrevTrainer1]
	ld [sBTPkmnPrevPrevTrainer1], a
	ld a, [sBTPkmnPrevTrainer2]
	ld [sBTPkmnPrevPrevTrainer2], a
	ld a, [sBTPkmnPrevTrainer3]
	ld [sBTPkmnPrevPrevTrainer3], a
	ld a, [wBT_OTPkmn1]
	ld [sBTPkmnPrevTrainer1], a
	ld a, [wBT_OTPkmn2]
	ld [sBTPkmnPrevTrainer2], a
	ld a, [wBT_OTPkmn3]
	ld [sBTPkmnPrevTrainer3], a
	call CloseSRAM
	ret
; 1f814e

INCLUDE "data/battle_tower/classes.asm"

INCLUDE "data/battle_tower/parties.asm"
