import SwiftUI
import CoreData

// MARK: - Stage One: Introduction and Connection
struct StageOneSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedInterests: Set<String> = []
    @State private var selectedSocialStatus: Set<String> = []
    @State private var selectedLifeStage: Set<String> = []
    
    private let interestOptions = [
        // Entertainment & Media
        "Music", "Movies", "TV Shows", "Podcasts", "Books", "Reading", "Gaming", "Streaming",
        "Theater", "Concerts", "Comedy", "Documentaries", "Anime", "Manga", "YouTube",
        
        // Sports & Fitness
        "Sports", "Fitness", "Running", "Gym", "Yoga", "Swimming", "Cycling", "Hiking",
        "Tennis", "Golf", "Basketball", "Soccer", "Football", "Baseball", "Martial Arts",
        "Dancing", "Boxing", "CrossFit", "Pilates", "Rock Climbing",
        
        // Creative & Arts
        "Art", "Photography", "Painting", "Drawing", "Sculpting", "Crafts", "Pottery",
        "Music Production", "Writing", "Poetry", "Blogging", "Graphic Design", "Video Editing",
        "Acting", "Singing", "Playing Instruments", "DJing",
        
        // Lifestyle & Hobbies
        "Cooking", "Baking", "Gardening", "Travel", "Camping", "Fishing", "Hunting",
        "Collecting", "Antiques", "Wine Tasting", "Coffee", "Tea", "Cocktails",
        "Fashion", "Makeup", "Skincare", "Interior Design", "Home Improvement",
        
        // Technology & Learning
        "Technology", "Programming", "Coding", "AI", "Cryptocurrency", "Trading",
        "Online Learning", "Languages", "History", "Science", "Astronomy", "Psychology",
        "Philosophy", "Politics", "Economics", "Business", "Marketing",
        
        // Social & Community
        "Volunteering", "Charity", "Community Service", "Mentoring", "Teaching",
        "Public Speaking", "Networking", "Social Media", "Blogging", "Vlogging",
        
        // Transportation & Adventure
        "Cars", "Motorcycles", "Boating", "Sailing", "Flying", "Aviation", "Space",
        "Adventure Sports", "Extreme Sports", "Paragliding", "Skydiving", "Scuba Diving",
        
        // Family & Relationships
        "Pets", "Dogs", "Cats", "Birds", "Fish", "Reptiles", "Horses", "Animal Rescue",
        "Parenting", "Childcare", "Family Activities", "Wedding Planning",
        
        // Health & Wellness
        "Meditation", "Mindfulness", "Yoga", "Pilates", "Massage", "Spa", "Wellness",
        "Nutrition", "Healthy Eating", "Mental Health", "Therapy", "Counseling",
        
        // Professional & Financial
        "Investing", "Real Estate", "Stock Market", "Cryptocurrency", "Trading",
        "Entrepreneurship", "Startups", "Business", "Finance", "Accounting", "Law",
        "Medicine", "Research", "Innovation", "Leadership", "Management"
    ]
    
    private let socialStatusOptions = [
        // Economic Class
        "Blue Collar", "White Collar", "Working Class", "Middle Class", "Upper Middle Class",
        "Lower Class", "Upper Class", "Wealthy", "Affluent", "Struggling", "Comfortable",
        
        // Professional Categories
        "Professional", "Managerial", "Executive", "C-Suite", "Director", "VP", "CEO",
        "Entrepreneur", "Business Owner", "Self-Employed", "Freelancer", "Consultant",
        "Contractor", "Gig Worker", "Part-Time", "Full-Time", "Unemployed", "Retired",
        
        // Industry Sectors
        "Healthcare Worker", "Medical Professional", "Nurse", "Doctor", "Therapist",
        "Teacher", "Professor", "Educator", "Academic", "Researcher", "Scientist",
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
        "Student", "Graduate Student", "PhD Student", "Postdoc", "Researcher",
        "Intern", "Trainee", "Apprentice", "Entry Level", "Junior", "Senior",
        "Expert", "Specialist", "Consultant", "Advisor", "Mentor",
        
        // Financial Status
        "High Income", "Low Income", "Fixed Income", "Disability", "Social Security",
        "Pension", "Investment Income", "Rental Income", "Business Income",
        "Commission Based", "Salary", "Hourly", "Contract", "Seasonal"
    ]
    
    private let lifeStageOptions = [
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stage One: Introduction & Connection")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                VStack(spacing: 20) {
                    // Interests
                    TagSelectionView(
                        title: "Interests",
                        options: interestOptions,
                        selectedTags: $selectedInterests
                    )
                    
                    // Social Status
                    TagSelectionView(
                        title: "Social Status",
                        options: socialStatusOptions,
                        selectedTags: $selectedSocialStatus
                    )
                    
                    // Life Stage
                    TagSelectionView(
                        title: "Life Stage",
                        options: lifeStageOptions,
                        selectedTags: $selectedLifeStage
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if !(client.interests?.isEmpty ?? true) {
                        TagDisplayView(title: "Interests", tags: client.interests ?? [])
                    }
                    
                    if !(client.socialStatus?.isEmpty ?? true) {
                        TagDisplayView(title: "Social Status", tags: client.socialStatus ?? [])
                    }
                    
                    if !(client.lifeStage?.isEmpty ?? true) {
                        TagDisplayView(title: "Life Stage", tags: client.lifeStage ?? [])
                    }
                    
                    if (client.interests?.isEmpty ?? true) && (client.socialStatus?.isEmpty ?? true) && (client.lifeStage?.isEmpty ?? true) {
                        Text("No connection information added yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            loadClientData()
        }
        .onChange(of: isEditMode) { _, editing in
            if !editing {
                saveClientData()
            }
        }
    }
    
    private func loadClientData() {
        selectedInterests = Set(client.interests ?? [])
        selectedSocialStatus = Set(client.socialStatus ?? [])
        selectedLifeStage = Set(client.lifeStage ?? [])
    }
    
    private func saveClientData() {
        client.interests = Array(selectedInterests)
        client.socialStatus = Array(selectedSocialStatus)
        client.lifeStage = Array(selectedLifeStage)
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving client connection data: \(error)")
        }
    }
}
