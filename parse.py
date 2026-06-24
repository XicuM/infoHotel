import json
import re

def parse_dart():
    with open('lib/views/services/hotel_services_view.dart', 'r') as f:
        content = f.read()

    # Just creating the JSON manually to be safe and accurate
    data = {
        "Savines": [
            {
                "titleKey": "hotel_map",
                "imagePaths": ["maps/savines.png"],
                "descriptionKey": "map_legend_savines",
                "headerIcon": "map_outlined",
                "accentColor": "42A5F5"
            },
            {
                "titleKey": "dinning_room",
                "imagePaths": ["facilities/savines/dining-room.jpg", "facilities/savines/dining-room-2.jpg"],
                "schedule": [
                    {"label": "Breakfast", "time": "08:00 – 10:00"},
                    {"label": "Dinner", "time": "19:30 – 21:30"}
                ],
                "features": [
                    {"icon": "restaurant_menu", "text": "Buffet-style breakfast & dinner"},
                    {"icon": "local_pizza", "text": "International dishes, pizza & pasta"},
                    {"icon": "tapas", "text": "Local specialities & themed nights"},
                    {"icon": "child_friendly", "text": "Children's menu available"}
                ],
                "headerIcon": "restaurant",
                "accentColor": "FF8F00"
            },
            {
                "titleKey": "Bar",
                "imagePaths": ["facilities/savines/bar.jpg", "facilities/savines/bar-2.jpg"],
                "isLiteral": True,
                "schedule": [
                    {"label": "Bar", "time": "10:00 – 00:00"},
                    {"label": "Snacks", "time": "10:00 – 18:00"}
                ],
                "features": [
                    {"icon": "local_bar", "text": "Cocktails, spirits & soft drinks"},
                    {"icon": "lunch_dining", "text": "Poolside snacks & sandwiches"},
                    {"icon": "icecream", "text": "Ice creams & cold drinks"},
                    {"icon": "deck", "text": "Terrace lounge seating"}
                ],
                "headerIcon": "local_bar",
                "accentColor": "AB47BC"
            },
            {
                "titleKey": "pools",
                "imagePaths": ["facilities/savines/pools.jpg", "facilities/savines/pools-2.jpg"],
                "hasSafetyRules": True,
                "schedule": [
                    {"label": "Open", "time": "10:00 – 20:30"}
                ],
                "features": [
                    {"icon": "pool", "text": "Outdoor hotel pool & apartments pool"},
                    {"icon": "child_care", "text": "Dedicated children's pool"},
                    {"icon": "wb_sunny", "text": "Sun terrace with free loungers"},
                    {"icon": "beach_access", "text": "Sea-view sun terrace & parasols"},
                    {"icon": "water", "text": "Lifeguard floats & safety equipment"}
                ],
                "headerIcon": "pool",
                "accentColor": "29B6F6"
            },
            {
                "titleKey": "Tennis",
                "imagePaths": ["facilities/savines/tennis.jpg", "facilities/savines/tennis-2.jpg"],
                "isLiteral": True,
                "features": [
                    {"icon": "sports_tennis", "text": "2 full-size tennis courts"},
                    {"icon": "sports", "text": "Rackets available at reception"}
                ],
                "headerIcon": "sports_tennis",
                "accentColor": "66BB6A"
            },
            {
                "titleKey": "Squash",
                "imagePaths": ["facilities/savines/squash.jpg", "facilities/savines/squash-2.jpg"],
                "isLiteral": True,
                "features": [
                    {"icon": "sports_handball", "text": "1 squash court on site"},
                    {"icon": "sports", "text": "Rackets & balls available"}
                ],
                "headerIcon": "sports_handball",
                "accentColor": "EF5350"
            },
            {
                "titleKey": "Crazy Golf",
                "imagePaths": ["facilities/savines/crazy-golf.jpg", "facilities/savines/crazy-golf-2.jpg"],
                "isLiteral": True,
                "features": [
                    {"icon": "golf_course", "text": "9-hole mini-golf course"},
                    {"icon": "child_friendly", "text": "Great fun for the whole family"},
                    {"icon": "free_breakfast", "text": "Free for hotel guests"}
                ],
                "headerIcon": "golf_course",
                "accentColor": "26A69A"
            },
            {
                "titleKey": "private_beach",
                "imagePaths": ["facilities/savines/beach.jpg", "facilities/savines/beach-2.jpg"],
                "features": [
                    {"icon": "beach_access", "text": "Direct access to private beach area"},
                    {"icon": "deck", "text": "Sun loungers & parasols on the beach"}
                ],
                "headerIcon": "beach_access",
                "accentColor": "42A5F5"
            }
        ],
        "Arenal": [
            {
                "titleKey": "hotel_map",
                "imagePaths": ["maps/arenal.png"],
                "descriptionKey": "map_legend_arenal",
                "headerIcon": "map_outlined",
                "accentColor": "42A5F5"
            },
            {
                "titleKey": "dinning_room",
                "imagePaths": ["facilities/arenal/dining-room.jpg", "facilities/arenal/dining-room-2.jpg"],
                "schedule": [
                    {"label": "Breakfast", "time": "08:00 – 10:00"},
                    {"label": "Dinner", "time": "19:30 – 21:30"}
                ],
                "features": [
                    {"icon": "restaurant_menu", "text": "Buffet breakfast & dinner"},
                    {"icon": "tapas", "text": "International & local specialities"}
                ],
                "headerIcon": "restaurant",
                "accentColor": "FF8F00"
            },
            {
                "titleKey": "Bar",
                "imagePaths": ["facilities/arenal/bar.jpg", "facilities/arenal/bar-2.jpg"],
                "isLiteral": True,
                "schedule": [
                    {"label": "Bar", "time": "09:00 – 01:00"}
                ],
                "features": [
                    {"icon": "local_bar", "text": "Full bar with cocktails & spirits"},
                    {"icon": "lunch_dining", "text": "Hot & cold snacks available"}
                ],
                "headerIcon": "local_bar",
                "accentColor": "AB47BC"
            },
            {
                "titleKey": "pools",
                "imagePaths": ["facilities/arenal/pools.jpg", "facilities/arenal/pools-2.jpg"],
                "hasSafetyRules": True,
                "schedule": [
                    {"label": "Outdoor pool", "time": "10:00 – 20:30"},
                    {"label": "Indoor pool", "time": "09:00 – 20:00"}
                ],
                "features": [
                    {"icon": "pool", "text": "Outdoor & indoor heated pool"},
                    {"icon": "child_care", "text": "Children's pool area"},
                    {"icon": "deck", "text": "Sun terrace with loungers"},
                    {"icon": "thermostat", "text": "Indoor pool heated in May & October"}
                ],
                "headerIcon": "pool",
                "accentColor": "29B6F6"
            },
            {
                "titleKey": "Gym / Sauna",
                "imagePaths": ["facilities/arenal/gym.jpg", "facilities/arenal/gym-2.jpg"],
                "isLiteral": True,
                "schedule": [
                    {"label": "Open", "time": "08:00 – 20:00"}
                ],
                "features": [
                    {"icon": "fitness_center", "text": "Fully equipped fitness centre"},
                    {"icon": "spa", "text": "Sauna & solarium"},
                    {"icon": "table_bar", "text": "Table tennis & billiards"}
                ],
                "headerIcon": "fitness_center",
                "accentColor": "EF5350"
            },
            {
                "titleKey": "Arenal Diving",
                "imagePaths": ["facilities/arenal/arenal-diving.jpg"],
                "isLiteral": True,
                "schedule": [
                    {"label": "Open", "time": "09:30 – 18:30"}
                ],
                "features": [
                    {"icon": "scuba_diving", "text": "On-site PADI diving centre"},
                    {"icon": "water", "text": "Guided dives in crystal-clear waters"},
                    {"icon": "school", "text": "Courses for all levels"},
                    {"icon": "sailing", "text": "Snorkelling & boat excursions"}
                ],
                "headerIcon": "scuba_diving",
                "accentColor": "26C6DA"
            }
        ]
    }

    with open('assets/data/hotels.json', 'w') as f:
        json.dump(data, f, indent=2)

if __name__ == '__main__':
    parse_dart()
