from sqlalchemy.orm import Session
from backend.app.models.patient import Patient
from backend.app.models.medication import Medication
from backend.app.models.meal_anchor import MealAnchor
from backend.app.models.scheduled_dose import ScheduledDose
from backend.app.models.interaction import ChelationConflict

class SeedService:
    @staticmethod
    def seed_initial_data(db: Session):
        # Check if already seeded
        if db.query(Patient).first() is not None:
            return

        print("[INIT] Seeding ChronoMed Clinical Database...")


        # 1. Patient Profile (Harry J.)
        patient = Patient(
            name="HARRY J.",
            age=58,
            conditions="Hypothyroidism, Osteopenia, Type-2 Pre-diabetes",
            wake_time="06:30 AM",
            sleep_time="10:30 PM",
            cortisol_peak="Morning Cortisol Peak • 09:45 AM",
            adherence_score=98
        )
        db.add(patient)
        db.commit()
        db.refresh(patient)

        # 2. Medications
        med_levo = Medication(
            rxcui="6185",
            name="Levothyroxine Sodium",
            dosage="50mcg",
            form="Tablet",
            instructions="Take in morning on empty stomach with a full glass of water, 60 minutes before breakfast.",
            requires_empty_stomach=True,
            empty_stomach_pre_meal_minutes=60,
            empty_stomach_post_meal_minutes=120,
            circadian_preference="MORNING"
        )
        med_multi = Medication(
            rxcui="74562",
            name="Multivitamin (Iron-Free)",
            dosage="1 Capsule",
            form="Capsule",
            instructions="Take after breakfast with water. Buffered by 90 minutes from morning thyroid medication.",
            requires_empty_stomach=False,
            empty_stomach_pre_meal_minutes=0,
            empty_stomach_post_meal_minutes=0,
            circadian_preference="MIDDAY"
        )
        med_calcium = Medication(
            rxcui="1886",
            name="Calcium Carbonate",
            dosage="500mg",
            form="Chewable Tablet",
            instructions="Take in afternoon with food or light snack. Maintain strict 4+ hour separation from Levothyroxine.",
            requires_empty_stomach=False,
            empty_stomach_pre_meal_minutes=0,
            empty_stomach_post_meal_minutes=0,
            circadian_preference="AFTERNOON"
        )

        db.add_all([med_levo, med_multi, med_calcium])
        db.commit()
        db.refresh(med_levo)
        db.refresh(med_multi)
        db.refresh(med_calcium)

        # 3. Meal Anchors
        breakfast = MealAnchor(
            patient_id=patient.id,
            name="BREAKFAST",
            time_str="08:30 AM",
            icon="restaurant"
        )
        lunch = MealAnchor(
            patient_id=patient.id,
            name="LUNCH",
            time_str="01:30 PM",
            icon="restaurant"
        )
        dinner = MealAnchor(
            patient_id=patient.id,
            name="DINNER",
            time_str="07:30 PM",
            icon="restaurant"
        )
        db.add_all([breakfast, lunch, dinner])
        db.commit()

        # 4. Scheduled Doses (Matching Today Screen)
        dose1 = ScheduledDose(
            id="dose_levo_0700",
            patient_id=patient.id,
            medication_id=med_levo.id,
            dose_time="07:00 AM",
            window_str="07:00 AM - 07:45 AM",
            status="TAKEN",
            adherence_percent=100,
            adherence_time="07:02 AM",
            tag="EMPTY STOMACH WINDOW",
            tag_color="amber",
            gap_info=None,
            is_active_focus=False,
            clinical_notes="Empty stomach condition fully satisfied (90m pre-meal window)."
        )

        dose2 = ScheduledDose(
            id="dose_multi_1000",
            patient_id=patient.id,
            medication_id=med_multi.id,
            dose_time="10:00 AM",
            window_str="09:30 AM - 10:30 AM",
            status="SCHEDULED",
            adherence_percent=100,
            adherence_time=None,
            tag="BUFFERED BY 90 MINS",
            tag_color="cyan",
            gap_info=None,
            is_active_focus=True,
            clinical_notes="Post-breakfast lipid & antioxidant absorption window."
        )

        dose3 = ScheduledDose(
            id="dose_calc_1530",
            patient_id=patient.id,
            medication_id=med_calcium.id,
            dose_time="03:30 PM",
            window_str="03:00 PM - 04:00 PM",
            status="SCHEDULED",
            adherence_percent=100,
            adherence_time=None,
            tag="4H CATION GAP RESPECTED",
            tag_color="emerald",
            gap_info="Gap 5h 28m",
            is_active_focus=False,
            clinical_notes="Critical 4-hour polyvalent cation chelation buffer maintained after Levothyroxine."
        )

        db.add_all([dose1, dose2, dose3])

        # 5. Chelation Conflict Rules
        conflict = ChelationConflict(
            drug_a="Levothyroxine Sodium",
            drug_b="Calcium Carbonate",
            gap_minutes=240,
            severity="HIGH",
            mechanism="Polyvalent cation binding in gastrointestinal lumen",
            rationale="Separation of 4+ hours prevents up to 80% loss in thyroid bioavailability."
        )
        db.add(conflict)

        db.commit()
        print("[SUCCESS] Clinical Database Seeded Successfully!")

seed_service = SeedService()

