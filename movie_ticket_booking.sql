-- Online Movie Ticket Booking System
-- This SQL script creates a movie ticket booking system with tables, stored procedures, triggers, and views.

-- 1. Movies Table
CREATE TABLE Movies (
    MovieID INT PRIMARY KEY AUTO_INCREMENT,
    MovieName VARCHAR(255) NOT NULL,
    Genre VARCHAR(100),
    Duration INT, -- in minutes
    ReleaseDate DATE
);

-- 2. Theaters Table
CREATE TABLE Theaters (
    TheaterID INT PRIMARY KEY AUTO_INCREMENT,
    TheaterName VARCHAR(255) NOT NULL,
    Location VARCHAR(255) NOT NULL,
    TotalScreens INT
);

-- 3. Screens Table
CREATE TABLE Screens (
    ScreenID INT PRIMARY KEY AUTO_INCREMENT,
    TheaterID INT,
    ScreenNumber INT,
    TotalSeats INT,
    FOREIGN KEY (TheaterID) REFERENCES Theaters(TheaterID) ON DELETE CASCADE
);

-- 4. Shows Table
CREATE TABLE Shows (
    ShowID INT PRIMARY KEY AUTO_INCREMENT,
    MovieID INT,
    TheaterID INT,
    ScreenID INT,
    ShowTime DATETIME,
    AvailableSeats INT,
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID) ON DELETE CASCADE,
    FOREIGN KEY (TheaterID) REFERENCES Theaters(TheaterID) ON DELETE CASCADE,
    FOREIGN KEY (ScreenID) REFERENCES Screens(ScreenID) ON DELETE CASCADE
);

-- 5. Customers Table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    PhoneNumber VARCHAR(15) UNIQUE NOT NULL
);

-- 6. Bookings Table
CREATE TABLE Bookings (
    BookingID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    ShowID INT,
    NumberOfSeats INT,
    BookingDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (ShowID) REFERENCES Shows(ShowID) ON DELETE CASCADE
);

-- Stored Procedure: Book Ticket
DELIMITER //
CREATE PROCEDURE BookTicket(
    IN p_CustomerID INT,
    IN p_ShowID INT,
    IN p_NumberOfSeats INT
)
BEGIN
    DECLARE availableSeats INT;
    SELECT AvailableSeats INTO availableSeats FROM Shows WHERE ShowID = p_ShowID;
    IF availableSeats >= p_NumberOfSeats THEN
        INSERT INTO Bookings (CustomerID, ShowID, NumberOfSeats) 
        VALUES (p_CustomerID, p_ShowID, p_NumberOfSeats);
        UPDATE Shows SET AvailableSeats = AvailableSeats - p_NumberOfSeats WHERE ShowID = p_ShowID;
        SELECT 'Booking Successful' AS Message;
    ELSE
        SELECT 'Not Enough Seats Available' AS Message;
    END IF;
END //
DELIMITER ;

-- Trigger: Prevent Overbooking
DELIMITER //
CREATE TRIGGER PreventOverbooking
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE seatsLeft INT;
    SELECT AvailableSeats INTO seatsLeft FROM Shows WHERE ShowID = NEW.ShowID;
    IF NEW.NumberOfSeats > seatsLeft THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Not enough seats available!';
    END IF;
END //
DELIMITER ;

-- View: Upcoming Shows
CREATE VIEW UpcomingShows AS
SELECT m.MovieName, t.TheaterName, s.ShowTime, s.AvailableSeats
FROM Shows s
JOIN Movies m ON s.MovieID = m.MovieID
JOIN Theaters t ON s.TheaterID = t.TheaterID
WHERE s.ShowTime > NOW();
