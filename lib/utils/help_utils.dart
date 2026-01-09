import 'package:manong_application/models/quick_response.dart';

class HelpUtils {
  final List<QuickResponse> quickResponses = [
    QuickResponse(
      text: "How to request a service?",
      response: """Here's how to request a service:

1. **Home** → Tap on the service you need
2. **Address** → We'll automatically detect your location
3. **Upload Photos** → Add 1-3 photos of the issue
4. **Payment** → Choose your payment method
5. **Find Manong** → Select from available experts
6. **Accept & Confirm** → Review and proceed to payment
7. **Track Progress** → Monitor status in My Requests

You can chat with your assigned Manong until the service is completed!""",
    ),
    QuickResponse(
      text: "Payment & Refund",
      response: """**Payment Methods:**
• GCash/Maya: Automatic browser redirect
• Cash: Marked as pending until paid

**Refund Policy:**
• Before acceptance: Full refund
• After acceptance: Amount minus ₱300
• During service: 50% refund
• After completion: No refund

Check refund status in Requests → Transactions icon""",
    ),
    QuickResponse(
      text: "Contact Support",
      response: """**Our Contact Details:**

📧 Email: [link url='mailto:support@manongapp.com']support@manongapp.com[/link]
📞 Phone: [link url='tel:09486373877'](0948) 637-3877[/link]
📍 Address: Quezon City, NCR, 1111, Philippines

**Website:** [link url='https://manongapp.com']https://manongapp.com[/link]

We're here to help you!""",
    ),
    QuickResponse(
      text: "What is Manong App?",
      response: """**Manong App is your on-demand service solution!**

Just like booking a ride or food delivery, you can book:
• 🛠️ **Plumbers**
• ⚡ **Electricians**
• 🔧 **Handymen**
• 🏠 **Various home services**

Need a leaking pipe fixed? Broken outlet repaired? Clogged sink cleared? Open the app, choose your service, and a nearby Manong will come to your rescue!

[link url='https://manongapp.com']Visit our website for more info[/link]""",
    ),
    QuickResponse(
      text: "Service Instructions",
      response: """**When your Manong arrives:**

1. **Verify Identity** - Check their name, photo & details in the app
2. **Confirm Service** - Review service type, rate & estimated cost  
3. **Prepare Area** - Keep workspace safe, clear & accessible
4. **Rate After** - Share honest ratings & feedback

This ensures a smooth and secure service experience!

Need help during service? Call: [link url='tel:09486373877'](0948) 637-3877[/link]""",
    ),

    QuickResponse(
      text: "How to Register",
      response: """**Step-by-Step Registration Guide:**

1. **Click Login/Register**
   - Open the Manong app and tap on the "Login" button

2. **Enter Mobile Number**
   - Input your active mobile number
   - Make sure you can receive SMS on this number

3. **Verify with OTP**
   - A 6-digit code will be sent to your mobile
   - Enter the code in the verification box

4. **Set Your Password**
   - Create a secure password (at least 8 characters)
   - Confirm your password

5. **Complete Your Profile**
   - Click "Complete Profile" to proceed
   - Enter your personal information:
     • First Name
     • Last Name  
     • Email Address
     • Address Category & Address
     • Upload Valid ID or Selfie

6. **Wait for Verification**
   - Your account will be on hold until we verify your identity
   - This usually takes 1-2 business days

7. **Request Services**
   - Once verified, you can now request services!

**Need help?** Contact: [link url='mailto:support@manongapp.com']support@manongapp.com[/link] or [link url='tel:09486373877'](0948) 637-3877[/link]""",
    ),
  ];

  String generateResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // Service request related
    if (message.contains('how to') && message.contains('request')) {
      return """Here's how to request a service:

1. **Home** → Tap on the service you need
2. **Address** → We'll automatically detect your location
3. **Upload Photos** → Add 1-3 photos of the issue
4. **Payment** → Choose your payment method
5. **Find Manong** → Select from available experts
6. **Accept & Confirm** → Review and proceed to payment
7. **Track Progress** → Monitor status in My Requests

You can chat with your assigned Manong until the service is completed!""";
    }

    // Payment related
    if (message.contains('payment') ||
        message.contains('pay') ||
        message.contains('refund')) {
      return """**Payment Methods:**
• GCash/Maya: Automatic browser redirect
• Cash: Marked as pending until paid

**Refund Policy:**
• Before acceptance: Full refund
• After acceptance: Amount minus ₱300
• During service: 50% refund
• After completion: No refund

Check refund status in Requests → Transactions icon""";
    }

    // Contact related
    if (message.contains('contact') ||
        message.contains('email') ||
        message.contains('phone') ||
        message.contains('call') ||
        message.contains('support')) {
      return """**Our Contact Details:**

📧 Email: [link url='mailto:support@manongapp.com']support@manongapp.com[/link]
📞 Phone: [link url='tel:09486373877'](0948) 637-3877[/link]
📍 Address: Quezon City, NCR, 1111, Philippines

**Website:** [link url='https://manongapp.com']https://manongapp.com[/link]

We're here to help you!""";
    }

    // What is Manong App
    if (message.contains('what is') ||
        message.contains('manong app') ||
        message.contains('this app') ||
        message.contains('how does this work')) {
      return """**Manong App is your on-demand service solution!**

Just like booking a ride or food delivery, you can book:
• 🛠️ **Plumbers**
• ⚡ **Electricians**
• 🔧 **Handymen**
• 🏠 **Various home services**

Need a leaking pipe fixed? Broken outlet repaired? Clogged sink cleared? Open the app, choose your service, and a nearby Manong will come to your rescue!

[link url='https://manongapp.com']Visit our website for more info[/link]""";
    }

    // Service instructions
    if (message.contains('instruction') ||
        message.contains('arrive') ||
        message.contains('meet') ||
        message.contains('verify') ||
        message.contains('prepare')) {
      return """**When your Manong arrives:**

1. **Verify Identity** - Check their name, photo & details in the app
2. **Confirm Service** - Review service type, rate & estimated cost  
3. **Prepare Area** - Keep workspace safe, clear & accessible
4. **Rate After** - Share honest ratings & feedback

This ensures a smooth and secure service experience!

Need help during service? Call: [link url='tel:09486373877'](0948) 637-3877[/link]""";
    }

    // Location/address related
    if (message.contains('location') ||
        message.contains('address') ||
        message.contains('where') ||
        message.contains('area')) {
      return """We automatically detect your location when you request a service. 

If you need to change the service location:
1. Go to **My Requests**
2. Select your ongoing service
3. Tap **Edit Location**
4. Set your new address

Your Manong will be notified of the location change!

Need help? Call: [link url='tel:09486373877'](0948) 637-3877[/link]""";
    }

    // Service types
    if (message.contains('plumber') ||
        message.contains('electrician') ||
        message.contains('handyman') ||
        message.contains('service type')) {
      return """We offer various home services:

• **Plumbing** - Leaks, clogs, installations, repairs
• **Electrical** - Wiring, outlets, lighting, repairs  
• **Handyman** - General repairs, assembly, maintenance
• **Cleaning** - Home, office, post-construction
• **And more!**

Tap on any service in the Home screen to see detailed options and pricing.

[link url='https://manongapp.com']See all services on our website[/link]""";
    }

    // Pricing/cost
    if (message.contains('price') ||
        message.contains('cost') ||
        message.contains('how much') ||
        message.contains('rate')) {
      return """Service pricing depends on:

• **Service Type** - Different services have different base rates
• **Complexity** - More complex jobs may cost more
• **Materials** - Any required materials are additional
• **Duration** - Longer services may have hourly rates

You'll see the estimated cost before confirming your service request. Final pricing may be adjusted based on the actual work required.

For pricing questions: [link url='mailto:support@manongapp.com']Email us[/link] or [link url='tel:09486373877']Call us[/link]""";
    }

    // Default response for unknown questions
    return """Thank you for your message! I understand you're asking about: "$userMessage"

I'm here to help! For more specific assistance, you can:
• Use the quick responses above for common questions
• Contact our support team: [link url='mailto:support@manongapp.com']support@manongapp.com[/link]
• Call us: [link url='tel:09486373877'](0948) 637-3877[/link]
• Visit: [link url='https://manongapp.com']https://manongapp.com[/link]

Is there anything else I can help you with today?""";
  }
}
