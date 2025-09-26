import Foundation

// MARK: - Tag Options Constants
struct TagOptions {
    
    // MARK: - Interest Options
    static let interestOptions = [
        // Entertainment & Media
        "Music", "Movies", "TV Shows", "Podcasts", "Books", "Reading", "Gaming", "Streaming",
        "Theater", "Concerts", "Comedy", "Documentaries", "Anime", "Manga", "YouTube",
        
        // Sports & Fitness
        "Sports", "Fitness", "Running", "Gym", "Yoga", "Swimming", "Cycling", "Hiking",
        "Tennis", "Golf", "Basketball", "Soccer", "Football", "Baseball", "Martial Arts",
        "Dancing", "Boxing", "CrossFit", "Pilates", "Rock Climbing",
        
        // Creative & Arts
        "Art", "Photography", "Painting", "Drawing", "Sculpting", "Crafts", "Pottery",
        "Music Production", "Writing", "Poetry", "Graphic Design", "Video Editing",
        "Acting", "Singing", "Playing Instruments", "DJing",
        
        // Lifestyle & Hobbies
        "Cooking", "Baking", "Gardening", "Travel", "Camping", "Fishing", "Hunting",
        "Collecting", "Antiques", "Wine Tasting", "Coffee", "Tea", "Cocktails",
        "Fashion", "Makeup", "Skincare", "Interior Design", "Home Improvement",
        
        // Technology & Learning
        "Technology", "Programming", "Coding", "AI", "Cryptocurrency", "Online Learning",
        "Languages", "History", "Science", "Astronomy", "Psychology",
        "Philosophy", "Politics", "Economics", "Marketing",
        
        // Social & Community
        "Volunteering", "Charity", "Community Service", "Mentoring", "Teaching",
        "Public Speaking", "Networking", "Social Media", "Vlogging",
        
        // Transportation & Adventure
        "Cars", "Motorcycles", "Boating", "Sailing", "Flying", "Aviation", "Space",
        "Adventure Sports", "Extreme Sports", "Paragliding", "Skydiving", "Scuba Diving",
        
        // Family & Relationships
        "Pets", "Dogs", "Cats", "Birds", "Fish", "Reptiles", "Horses", "Animal Rescue",
        "Parenting", "Childcare", "Family Activities", "Wedding Planning",
        
        // Health & Wellness
        "Meditation", "Mindfulness", "Massage", "Spa", "Wellness",
        "Nutrition", "Healthy Eating", "Mental Health", "Therapy", "Counseling",
        
        // Professional & Financial
        "Investing", "Real Estate", "Stock Market",
        "Entrepreneurship", "Startups", "Finance", "Accounting", "Law",
        "Medicine", "Research", "Innovation", "Leadership", "Management"
    ]
    
    // MARK: - Social Status Options
    static let socialStatusOptions = [
        // Economic Class
        "Blue Collar", "White Collar", "Working Class", "Middle Class", "Upper Middle Class",
        "Lower Class", "Upper Class", "Wealthy", "Affluent", "Struggling", "Comfortable",
        
        // Professional Categories
        "Professional", "Managerial", "Executive", "C-Suite", "Director", "VP", "CEO",
        "Entrepreneur", "Business Owner", "Self-Employed", "Freelancer", "Consultant",
        "Contractor", "Gig Worker", "Part-Time", "Full-Time", "Unemployed", "Retired",
        
        // Industry Sectors
        "Healthcare Worker", "Medical Professional", "Nurse", "Doctor", "Therapist",
        "Teacher", "Professor", "Educator", "Academic", "Scientist",
        "Engineer", "Software Engineer", "Data Scientist", "Analyst", "Developer",
        "Designer", "Artist", "Creative Professional", "Marketing Professional",
        "Sales Professional", "Customer Service", "Administrative", "Support Staff",
        
        // Government & Public Sector
        "Government Employee", "Public Servant", "Civil Servant", "Military", "Veteran",
        "Police Officer", "Firefighter", "Emergency Services", "Public Safety",
        
        // Service Industry
        "Service Worker", "Retail Worker", "Hospitality", "Food Service", "Tourism",
        "Transportation", "Logistics", "Warehouse", "Manufacturing", "Construction",
        "Maintenance", "Cleaning", "Security", "Janitorial",
        
        // Education & Training
        "Student", "Graduate Student", "PhD Student", "Postdoc",
        "Intern", "Trainee", "Apprentice", "Entry Level", "Junior", "Senior",
        "Expert", "Specialist", "Advisor", "Mentor",
        
        // Financial Status
        "High Income", "Low Income", "Fixed Income", "Disability", "Social Security",
        "Pension", "Investment Income", "Rental Income", "Business Income",
        "Commission Based", "Salary", "Hourly", "Contract", "Seasonal"
    ]
    
    // MARK: - Life Stage Options
    static let lifeStageOptions = [
        // Relationship Status
        "Single", "Dating", "In a Relationship", "Engaged", "Newly Married", "Married",
        "Separated", "Divorced", "Widowed", "Remarried", "Common Law", "Domestic Partnership",
        "Long Distance", "Open Relationship", "Polyamorous", "Asexual", "Celibate",
        
        // Family Status
        "Childless", "Expecting", "New Parent", "Parent", "Single Parent", "Step Parent",
        "Adoptive Parent", "Foster Parent", "Empty Nester", "Grandparent", "Great Grandparent",
        "Guardian", "Caretaker", "Family Caregiver", "Pet Parent", "Child-Free by Choice",
        
        // Age & Life Phases
        "Teenager", "Young Adult", "Millennial", "Gen X", "Boomer", "Gen Z", "Gen Alpha",
        "Early 20s", "Late 20s", "Early 30s", "Late 30s", "Early 40s", "Late 40s",
        "Early 50s", "Late 50s", "Early 60s", "Late 60s", "70s", "80s", "90s+",
        
        // Education & Career Stage
        "High School Student", "College Student", "Graduate Student", "PhD Student",
        "Recent Graduate", "Entry Level", "Just Started Working", "Early Career",
        "Mid-Career", "Senior Professional", "Executive Level", "Pre-Retirement",
        "Retired", "Semi-Retired", "Career Change", "Career Break", "Sabbatical",
        "Unemployed", "Job Searching", "Freelancing", "Consulting", "Part-Time",
        
        // Life Transitions
        "Starting Out", "Building Career", "Peak Earning Years", "Pre-Retirement Planning",
        "Retirement Planning", "Retirement", "Elder Care", "Health Challenges",
        "Recovery", "Reinvention", "Second Career", "Volunteer Work", "Mentoring",
        
        // Financial Life Stage
        "Building Credit", "First Home Buyer", "Homeowner", "Real Estate Investor",
        "Debt Free", "Building Wealth", "Wealth Preservation", "Estate Planning",
        "Financial Independence", "Early Retirement", "Traditional Retirement",
        
        // Health & Wellness Stage
        "Health Conscious", "Fitness Focused", "Wellness Journey", "Medical Challenges",
        "Recovery", "Preventive Care", "Chronic Condition Management", "Caregiving",
        "Mental Health Focus", "Spiritual Journey", "Mindfulness Practice",
        
        // Social & Community Stage
        "Social Butterfly", "Introvert", "Community Leader", "Volunteer", "Mentor",
        "Networker", "Influencer", "Activist", "Advocate", "Philanthropist",
        "Local Business Owner", "Community Builder", "Social Media Active",
        
        // Personal Development
        "Self-Improvement", "Learning Phase", "Skill Building", "Certification Pursuit",
        "Hobby Development", "Creative Phase", "Spiritual Growth", "Personal Growth",
        "Life Coaching", "Therapy", "Counseling", "Support Group", "Recovery Group"
    ]
}

// MARK: - Relationship Options Constants
struct RelationshipOptions {
    
    // MARK: - Relationship Types
    enum RelationshipType: String, CaseIterable, Identifiable {
        case parent = "Parent"
        case child = "Child"
        case spouse = "Spouse"
        case sibling = "Sibling"
        case guardian = "Guardian"
        case ward = "Ward"
        case grandparent = "Grandparent"
        case grandchild = "Grandchild"
        case uncle = "Uncle"
        case aunt = "Aunt"
        case nephew = "Nephew"
        case niece = "Niece"
        case cousin = "Cousin"
        case inLaw = "In-Law"
        case stepParent = "Step-Parent"
        case stepChild = "Step-Child"
        case stepSibling = "Step-Sibling"
        case halfSibling = "Half-Sibling"
        case businessPartner = "Business Partner"
        case employer = "Employer"
        case employee = "Employee"
        case friend = "Friend"
        case neighbor = "Neighbor"
        case other = "Other"
        
        var id: String { self.rawValue }
        
        // MARK: - Bidirectional Mapping
        var inverseRelationship: RelationshipType {
            switch self {
            case .parent: return .child
            case .child: return .parent
            case .spouse: return .spouse
            case .sibling: return .sibling
            case .guardian: return .ward
            case .ward: return .guardian
            case .grandparent: return .grandchild
            case .grandchild: return .grandparent
            case .uncle: return .nephew
            case .aunt: return .niece
            case .nephew: return .uncle
            case .niece: return .aunt
            case .cousin: return .cousin
            case .inLaw: return .inLaw
            case .stepParent: return .stepChild
            case .stepChild: return .stepParent
            case .stepSibling: return .stepSibling
            case .halfSibling: return .halfSibling
            case .businessPartner: return .businessPartner
            case .employer: return .employee
            case .employee: return .employer
            case .friend: return .friend
            case .neighbor: return .neighbor
            case .other: return .other
            }
        }
        
        // MARK: - Categories
        var category: RelationshipCategory {
            switch self {
            case .parent, .child, .grandparent, .grandchild, .stepParent, .stepChild:
                return .family
            case .spouse, .sibling, .stepSibling, .halfSibling:
                return .immediateFamily
            case .uncle, .aunt, .nephew, .niece, .cousin, .inLaw:
                return .extendedFamily
            case .guardian, .ward:
                return .guardianship
            case .businessPartner, .employer, .employee:
                return .business
            case .friend, .neighbor, .other:
                return .other
            }
        }
        
        var icon: String {
            switch self.category {
            case .immediateFamily: return "person.2.fill"
            case .family: return "person.3.fill"
            case .extendedFamily: return "person.3.sequence.fill"
            case .guardianship: return "shield.fill"
            case .business: return "briefcase.fill"
            case .other: return "person.circle.fill"
            }
        }
    }
    
    enum RelationshipCategory: String, CaseIterable {
        case immediateFamily = "Immediate Family"
        case family = "Family"
        case extendedFamily = "Extended Family"
        case guardianship = "Guardianship"
        case business = "Business"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .immediateFamily: return "person.2.fill"
            case .family: return "person.3.fill"
            case .extendedFamily: return "person.3.sequence.fill"
            case .guardianship: return "shield.fill"
            case .business: return "briefcase.fill"
            case .other: return "person.circle.fill"
            }
        }
    }
}
