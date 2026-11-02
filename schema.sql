CREATE DATABASE IF NOT EXISTS WildlifeDB CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE WildlifeDB;

CREATE TABLE IF NOT EXISTS Species (
  Species_ID INT PRIMARY KEY,
  Species_Name VARCHAR(100) NOT NULL UNIQUE,
  Scientific_Name VARCHAR(150),
  Conservation_Status VARCHAR(50),
  Habitat VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Animal (
  Animal_ID INT PRIMARY KEY,
  Tag_No VARCHAR(20) NOT NULL UNIQUE,
  Gender VARCHAR(10),
  Age INT CHECK (Age >= 0),
  Health_Status VARCHAR(30),
  Species_ID INT,
  FOREIGN KEY (Species_ID) REFERENCES Species(Species_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Rescue_Team (
  Team_ID INT PRIMARY KEY,
  Team_Name VARCHAR(100) NOT NULL,
  Contact_No VARCHAR(15)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Rescue_Event (
  Rescue_ID INT PRIMARY KEY,
  Rescue_Date DATE NOT NULL,
  Rescue_Location VARCHAR(150),
  Rescue_Reason VARCHAR(200),
  Animal_ID INT NOT NULL,
  FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID),
  Team_ID INT NOT NULL,
  FOREIGN KEY (Team_ID) REFERENCES Rescue_Team(Team_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Veterinarian (
  Vet_ID INT PRIMARY KEY,
  Name VARCHAR(100) NOT NULL,
  Specialization VARCHAR(100),
  Contact_No VARCHAR(15)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Medical_Record (
  Record_ID INT PRIMARY KEY,
  Diagnosis VARCHAR(200),
  Treatment VARCHAR(300),
  Record_Date DATE,
  Animal_ID INT NOT NULL,
  FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID),
  Vet_ID INT NOT NULL,
  FOREIGN KEY (Vet_ID) REFERENCES Veterinarian(Vet_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Rehabilitation_Program (
  Program_ID INT PRIMARY KEY,
  Program_Name VARCHAR(100) NOT NULL,
  Duration INT CHECK (Duration >= 0),
  Objective VARCHAR(300)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Rehabilitation_Record (
  Rehab_ID INT PRIMARY KEY,
  Start_Date DATE,
  End_Date DATE,
  Progress_Status VARCHAR(50),
  Animal_ID INT NOT NULL,
  FOREIGN KEY (Animal_ID) REFERENCES Animal(Animal_ID),
  Program_ID INT NOT NULL,
  FOREIGN KEY (Program_ID) REFERENCES Rehabilitation_Program(Program_ID),
  CHECK (End_Date IS NULL OR End_Date >= Start_Date)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Animal_Audit (
  Audit_ID INT AUTO_INCREMENT PRIMARY KEY,
  Animal_ID INT NOT NULL,
  Old_Status VARCHAR(30),
  New_Status VARCHAR(30),
  Change_Time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS animal_health_after_update;
DELIMITER $$
CREATE TRIGGER animal_health_after_update AFTER UPDATE ON Animal FOR EACH ROW BEGIN
IF NOT (OLD.Health_Status <=> NEW.Health_Status) THEN
INSERT INTO Animal_Audit (Animal_ID,Old_Status,New_Status) VALUES (OLD.Animal_ID,OLD.Health_Status,NEW.Health_Status);
END IF;
END$$
DELIMITER ;