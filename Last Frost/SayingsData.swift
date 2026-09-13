import Foundation

enum SayingVerdict: Int {
    case truth = 0, half, myth

    var name: String {
        switch self {
        case .truth: return "Truth"
        case .half: return "Half-truth"
        case .myth: return "Myth"
        }
    }
}

struct Saying: Identifiable, Equatable {
    let month: Int
    let text: String
    let verdict: SayingVerdict
    let note: String
    var id: String { text }
    var monthName: String { Almanac.monthNames[max(0, min(11, month - 1))] }
}

extension Saying {
    init(_ month: Int, _ text: String, _ verdict: SayingVerdict, _ note: String) {
        self.month = month; self.text = text; self.verdict = verdict; self.note = note
    }
}

enum Sayings {
    static let all: [Saying] = SayingsA.list + SayingsB.list + SayingsC.list + SayingsD.list

    static func forMonth(_ month: Int) -> [Saying] { all.filter { $0.month == month } }

    static func ofDay(_ day: Int) -> Saying {
        let month = Almanac.parts(of: day).month
        let pool = forMonth(month)
        guard !pool.isEmpty else { return all[0] }
        return pool[abs(day) % pool.count]
    }

    static func plate(_ month: Int) -> String { "mo_\(max(1, min(12, month)))" }
}

enum SayingsA {
    static let list: [Saying] = [
        Saying(1, "Snow is the poor man's manure.", .half,
               "A blanket of snow holds the soil at one temperature, stops the freeze-and-thaw that heaves garlic out of the ground, and melts slowly into it in spring. The nitrogen it brings down from the air is real but tiny, a pound or two an acre; the manure part is folklore, the blanket part is sound."),
        Saying(1, "Plant garlic on the shortest day, harvest on the longest.", .half,
               "It works where the ground never freezes, in zones 8 and 9, because garlic wants six weeks of root growth before winter. In zone 6 the shortest day is too late: the plan counts six weeks back from your first frost, which lands in September or October. The longest-day harvest is early anywhere; wait for the leaves to brown."),
        Saying(1, "A year of snow, a year of plenty.", .half,
               "Snow cover protects overwintering crops and the soil life from the killing dry cold, and its slow melt recharges the ground for spring sowing, so a snowy winter often is followed by a good year. But the plenty comes from the moisture and the insulation, not from the snow itself, and a snowless mild winter can do as well."),
        Saying(2, "If Candlemas Day be fair and bright, winter will have another flight.", .myth,
               "Candlemas is the second of February, the day the groundhog borrowed. A sunny February morning says nothing about April; the records were checked for a century and a half and the day predicts the rest of winter no better than a coin. The frost dates in the almanac are averages of real thermometers, which is the better guide."),
        Saying(2, "Parsley goes nine times to the devil before it comes up.", .truth,
               "Parsley seed takes three to four weeks to germinate and does it unevenly, so the sowing looks dead for a month. The devil was a way of explaining the wait. Soak the seed overnight, sow in warm compost indoors in February, and be patient; the plants live two years once they are up."),
        Saying(2, "Chit your potatoes on the windowsill by Valentine's Day.", .half,
               "Chitting, standing the seed potatoes in a light cool place to sprout short green shoots, gives the early varieties a head start of a fortnight. Mid-February is right where potatoes go out in mid-March, in zone 7 and warmer. In zone 5 the ground is not workable until late April, and the chitting starts a month later."),
        Saying(3, "Plant peas on St Patrick's Day.", .half,
               "Peas are hardy and go in four to six weeks before the last frost, and in zone 6, with a last frost of April 1, the seventeenth of March lands inside that window exactly. In zone 4 the ground is still frozen on that day and in zone 8 the peas should already be up. The saying is true for one zone and a calendar for the rest."),
        Saying(3, "Sow peas and beans on David and Chad, be the weather good or bad.", .myth,
               "The first and second of March are the feast days of two Welsh saints, and the rhyme is a memory aid, not agronomy. Peas will stand a cold sowing, but broad beans sown into waterlogged March soil rot before they root. The test is the soil: if it sticks to the boot, wait, whatever the calendar says."),
        Saying(3, "March dust is worth a king's ransom.", .truth,
               "A dry March lets the winter-dug soil be raked to a fine crumb, the tilth that small seeds need to germinate evenly. A wet March means sowing into cold mud, poor germination and a late start. Dry spring soil is worth more than any fertiliser, which is why the saying survives.")
    ]
}

enum SayingsB {
    static let list: [Saying] = [
        Saying(4, "Plant potatoes on Good Friday.", .myth,
               "Good Friday moves by five weeks from one year to the next, from late March to late April, so it cannot be a growing signal. It became the potato day because it was a holiday from work. The potato wants soil at 45 degrees and a sprouted eye; in zone 6 that is around the last frost, and the almanac counts it for you."),
        Saying(4, "April showers bring May flowers.", .truth,
               "Spring rain on warming soil is what the plot runs on. The direct sowings of April, carrots, beets, lettuce and the second peas, germinate on the moisture the showers leave, and the transplants put out roots. A dry April is the one that needs the watering can, and the crops that follow are the ones that suffer."),
        Saying(4, "When the forsythia blooms, sow peas and lettuce.", .truth,
               "Phenology, reading the plants rather than the calendar, works because the forsythia and the soil are warmed by the same spring. Forsythia opens at a soil temperature of about 45 degrees, which is what peas and lettuce want to germinate. It is an honest sign of your own garden's season, whatever the zone map says."),
        Saying(5, "Ne'er cast a clout till May be out.", .truth,
               "The May is the hawthorn blossom, and in the English countryside it opens at the end of the last frosts. Do not shed a layer, and do not set out the tender crops, until it is out. In the almanac the same rule is the last frost date plus a week or two for the very tender: tomatoes, peppers, basil, squash."),
        Saying(5, "Plant corn when oak leaves are the size of a squirrel's ear.", .truth,
               "Oak is the last of the big trees to leaf and does it when the soil has warmed to about 55 degrees, which is what corn seed needs to germinate rather than rot. The squirrel's ear is a good measure of the size. It is the same rule the almanac uses, counted from the last frost plus two weeks."),
        Saying(5, "Sow beans when the elm leaves are as big as a shilling.", .truth,
               "The elm leafs out late and its leaves reach coin size at the end of the frosts. Beans are tender, and a sowing into cold soil sits and rots; the elm says when the soil is ready. Where the elms are gone, the lilac in full flower or the oak leaves serve as well."),
        Saying(6, "A dry May and a dripping June brings all things into tune.", .half,
               "It describes a good year for the field crops: dry sowing weather, then rain when the plants are growing hard. In the garden a dripping June also brings slugs and the first blight, so the saying is half a blessing. What is true is that the June water matters more than the May water for nearly everything sown in spring."),
        Saying(6, "Sow lettuce by the light of the moon.", .myth,
               "Moon sowing, leaf crops on the waxing moon and roots on the waning, has been tested in trials for a hundred years and shows no effect the soil temperature does not explain. What the moon calendar does is get people into the garden on a regular rhythm, which is the real reason the followers get good crops."),
        Saying(6, "A swarm of bees in June is worth a silver spoon.", .truth,
               "A June swarm has time to build up before winter and to work the summer flowers, so it was valuable to a beekeeper; a July swarm was not worth a fly. For the plot, June is when the squash, beans and tomatoes are opening their first flowers and want the pollinators, so a garden full of bees in June is a garden with fruit in August.")
    ]
}

enum SayingsC {
    static let list: [Saying] = [
        Saying(7, "St Swithin's Day, if thou dost rain, for forty days it will remain.", .myth,
               "The fifteenth of July has been checked against the rainfall records many times, and forty wet days have never followed it. What is true underneath is that the summer weather pattern is often set by mid-July, so a wet St Swithin's tends to sit inside a wet spell. The forty days are poetry."),
        Saying(7, "Sow turnips on St James's Day, wet or dry.", .truth,
               "The twenty-fifth of July is about fourteen weeks before the first frost of zone 6, and turnips take eight to ten weeks, so the sowing ripens a fall crop with room to spare. It is the almanac's fall-sowing rule in a rhyme. In zone 4, count back from a first frost of October 1 and the day is a fortnight earlier."),
        Saying(7, "Never trust a July sky.", .half,
               "July thunderstorms come up in an afternoon out of a clear morning, and a hard one flattens the corn and splits the ripening tomatoes. The saying is a warning to keep watering through a hot spell and not to wait for the rain that looks about to come. It is not a forecast, but it is good advice."),
        Saying(8, "Dry August and warm doth harvest no harm.", .truth,
               "The grain harvest wanted dry weather, and so does the garden's: onions and garlic cure in it, beans dry for seed in it, and the tomatoes ripen without splitting. A dry August means watering the beans and squash by hand, but the harvest itself comes in clean. The wet August is the one that brings blight and mildew."),
        Saying(8, "Onion skins very thin, mild winter coming in; onion skins thick and tough, coming winter cold and rough.", .myth,
               "The thickness of an onion's skin is set by the variety and by how the bulb was grown and cured, not by the winter to come. A dry August makes thick skins; a wet one makes thin. The onions know nothing about January. Grow them for the storage skins anyway, since the thick ones keep."),
        Saying(8, "Sow spinach when the Michaelmas daisies bud.", .truth,
               "The asters bud in the middle of August, and that is the fall spinach sowing: eight to ten weeks before the first frost, when the nights have begun to cool and the seed will not bolt. Spring-sown spinach is racing the heat; the August sowing has the whole of autumn to make leaf and will stand into winter under a cloche.")
    ]
}

enum SayingsD {
    static let list: [Saying] = [
        Saying(9, "Blackberries after Michaelmas belong to the devil.", .truth,
               "By the end of September the blackberries left on the bramble are soft, wet with the autumn dew, and colonised by grey mould and the flies that lay in them. The devil was a way of saying do not eat them. The same is true of the last raspberries and the split tomatoes: what is not picked by the first cold nights is not worth picking."),
        Saying(9, "Garlic in by the end of September.", .half,
               "Garlic wants six weeks of root growth before the ground freezes, so the sowing is counted back from the first frost: in zone 6, with a first frost of October 31, that is the middle of September, and the saying is right. In zone 8 the end of September is a month early and the garlic will make too much top; in zone 4 it is a fortnight late."),
        Saying(9, "Red sky at night, gardener's delight.", .truth,
               "Where the weather comes from the west, a red sunset means the western sky is clear and dry air is on its way, and a red dawn means the clear sky has already passed east and the rain is behind it. It holds on most days in the temperate zones. It is a forecast for tomorrow, not the week, but for deciding whether to water it is worth having."),
        Saying(10, "When the leaves fall early, the winter will be mild.", .myth,
               "Trees drop their leaves in response to the past summer and the present autumn, drought and the first frosts, not to the winter ahead. An early leaf fall follows a dry summer. The winter that follows is as likely to be hard as mild. Use the leaves for leaf mould and use the frost dates for the plan."),
        Saying(10, "A heavy crop of holly berries means a hard winter.", .myth,
               "A heavy berry crop means a good flowering the previous May and enough bees to pollinate it; the holly is reporting on last spring, not next winter. The idea that nature stocks the larder for the birds ahead of a hard winter is kind but wrong. The same goes for the acorns and the rowan."),
        Saying(10, "Frost sweetens the parsnip.", .truth,
               "Below about 40 degrees the parsnip, like the carrot, kale and Brussels sprout, converts some of its stored starch to sugar, which lowers the freezing point of its sap and keeps the cells from bursting. The sugar is why a parsnip lifted after a hard frost tastes as it should and one lifted in September tastes of little."),
        Saying(11, "Garlic in by Bonfire Night.", .half,
               "The fifth of November is the last sensible garlic date for a mild maritime climate, where the ground does not freeze until January. In the almanac the rule is six weeks before the first frost, which for zone 7 is the start of October and for zone 5 the start of September. Bonfire Night works for zone 8 and later; earlier zones are already too late."),
        Saying(11, "Thunder in November, a fertile year to come.", .myth,
               "A November thunderstorm is a rare thing in a cold climate and was taken as an omen, but it predicts nothing about the next summer. The fertility of the coming year is in the compost heap being built now and the leaf mould being stacked, not in the sky."),
        Saying(11, "Sprouts are best picked after a frost.", .truth,
               "Brussels sprouts convert starch to sugar in the cold, like parsnips, and lose the bitter edge that puts people off them. Pick from the bottom of the stem upward after the first hard frost, and leave the top to keep growing. The same cold that sweetens them ends the tender crops, which is why the plan counts everything from it."),
        Saying(12, "A green Christmas makes a fat churchyard.", .myth,
               "A mild December was thought to breed fever; in fact the winter deaths came with the hard cold, not the warm. In the garden a green Christmas means the kale, leeks and parsnips are still growing and the soil can still be dug. What a mild winter does bring is the slugs and the aphids through unchecked, and the plan takes that into account in spring."),
        Saying(12, "Frost on the shortest day is good for the wheat.", .half,
               "A hard frost on frozen ground does the overwintering crops no harm and kills some of the pests that would have eaten them; a hard frost on wet, unfrozen ground heaves them out. The winter crops of the plot, garlic, fava beans and onion sets, like a steady cold under mulch and dislike a thaw. The frost is fine; the thaw is the trouble."),
        Saying(12, "Dig the beds at Christmas and let the frost do the work.", .half,
               "On a heavy clay soil, rough digging before the hard frosts lets the freezing water shatter the clods into a crumb by spring, and the saying is sound. On a light or sandy soil, or a bed run without digging, the same treatment destroys the structure and the worms. Know your soil first; the clay gardener digs and the others mulch.")
    ]
}
