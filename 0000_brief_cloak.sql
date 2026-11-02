CREATE TABLE `Animal` (
	`Animal_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Tag_No` text NOT NULL,
	`Gender` text,
	`Age` integer,
	`Health_Status` text,
	`Species_ID` integer,
	FOREIGN KEY (`Species_ID`) REFERENCES `Species`(`Species_ID`) ON UPDATE no action ON DELETE no action,
	CONSTRAINT "Animal_Age_nonnegative" CHECK("Animal"."Age" >= 0)
);
--> statement-breakpoint
CREATE UNIQUE INDEX `Animal_Tag_No_unique` ON `Animal` (`Tag_No`);--> statement-breakpoint
CREATE TABLE `Animal_Audit` (
	`Audit_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Animal_ID` integer NOT NULL,
	`Old_Status` text,
	`New_Status` text,
	`Change_Time` text DEFAULT CURRENT_TIMESTAMP
);
--> statement-breakpoint
CREATE TABLE `Medical_Record` (
	`Record_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Diagnosis` text,
	`Treatment` text,
	`Record_Date` text,
	`Animal_ID` integer NOT NULL,
	`Vet_ID` integer NOT NULL,
	FOREIGN KEY (`Animal_ID`) REFERENCES `Animal`(`Animal_ID`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`Vet_ID`) REFERENCES `Veterinarian`(`Vet_ID`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `Rehabilitation_Program` (
	`Program_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Program_Name` text NOT NULL,
	`Duration` integer,
	`Objective` text,
	CONSTRAINT "Rehabilitation_Program_Duration_nonnegative" CHECK("Rehabilitation_Program"."Duration" >= 0)
);
--> statement-breakpoint
CREATE TABLE `Rehabilitation_Record` (
	`Rehab_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Start_Date` text,
	`End_Date` text,
	`Progress_Status` text,
	`Animal_ID` integer NOT NULL,
	`Program_ID` integer NOT NULL,
	FOREIGN KEY (`Animal_ID`) REFERENCES `Animal`(`Animal_ID`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`Program_ID`) REFERENCES `Rehabilitation_Program`(`Program_ID`) ON UPDATE no action ON DELETE no action,
	CONSTRAINT "rehab_dates" CHECK("Rehabilitation_Record"."End_Date" IS NULL OR "Rehabilitation_Record"."End_Date" >= "Rehabilitation_Record"."Start_Date")
);
--> statement-breakpoint
CREATE TABLE `Rescue_Event` (
	`Rescue_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Rescue_Date` text NOT NULL,
	`Rescue_Location` text,
	`Rescue_Reason` text,
	`Animal_ID` integer NOT NULL,
	`Team_ID` integer NOT NULL,
	FOREIGN KEY (`Animal_ID`) REFERENCES `Animal`(`Animal_ID`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`Team_ID`) REFERENCES `Rescue_Team`(`Team_ID`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `Rescue_Team` (
	`Team_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Team_Name` text NOT NULL,
	`Contact_No` text
);
--> statement-breakpoint
CREATE TABLE `Species` (
	`Species_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Species_Name` text NOT NULL,
	`Scientific_Name` text,
	`Conservation_Status` text,
	`Habitat` text
);
--> statement-breakpoint
CREATE UNIQUE INDEX `Species_Species_Name_unique` ON `Species` (`Species_Name`);--> statement-breakpoint
CREATE TABLE `Veterinarian` (
	`Vet_ID` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`Name` text NOT NULL,
	`Specialization` text,
	`Contact_No` text
);
--> statement-breakpoint
CREATE TRIGGER animal_health_after_update AFTER UPDATE OF Health_Status ON Animal
WHEN OLD.Health_Status IS NOT NEW.Health_Status
BEGIN
INSERT INTO Animal_Audit (Animal_ID, Old_Status, New_Status) VALUES (OLD.Animal_ID, OLD.Health_Status, NEW.Health_Status);
END;
