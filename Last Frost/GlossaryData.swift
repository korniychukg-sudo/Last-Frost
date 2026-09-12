import Foundation

struct Term: Identifiable {
    let term: String
    let means: String
    var id: String { term }
}

enum Glossary {
    static let terms: [Term] = GlossaryA.list + GlossaryB.list + GlossaryC.list + GlossaryD.list + GlossaryE.list

    static func find(_ name: String) -> Term? { terms.first { $0.term == name } }
}

enum GlossaryA {
    static let list: [Term] = [
        Term(term: "Last frost date", means: "The average date of the last freezing night in spring. Every spring sowing and transplant in the almanac is counted in weeks before or after it."),
        Term(term: "First frost date", means: "The average date of the first freezing night in autumn. Fall sowings, garlic and cover crops are counted back from it, and it ends the tender crops."),
        Term(term: "Frost-free season", means: "The days between the last spring frost and the first fall frost. A crop's days to maturity must fit inside it, with a margin, or the crop is started indoors."),
        Term(term: "Hardiness zone", means: "A band of average winter minimum temperature, numbered 3 to 10 here. It gives the usual frost dates for a region; a garden's own dates can differ by a fortnight."),
        Term(term: "Hardy", means: "Able to stand a hard frost. Peas, spinach, kale, garlic and onions are sown or set out weeks before the last frost."),
        Term(term: "Half-hardy", means: "Able to take a light frost but not a hard one. Lettuce, beets, carrots and cauliflower go in a week or two before the last frost."),
        Term(term: "Tender", means: "Killed by frost. Beans, corn and sunflowers wait until the last frost has passed and the soil has warmed."),
        Term(term: "Very tender", means: "Killed by frost and checked by cold soil. Tomatoes, peppers, cucumbers, squash and basil go out one to three weeks after the last frost."),
        Term(term: "Direct sowing", means: "Sowing seed where the plant will grow, in a drill in the bed. Root crops, peas, beans and corn are sown direct."),
        Term(term: "Indoor sowing", means: "Starting seed in trays or pots under cover, weeks before the garden is warm enough, so the plant has a head start. Tomatoes, peppers and brassicas begin this way.")
    ]
}

enum GlossaryB {
    static let list: [Term] = [
        Term(term: "Drill", means: "A shallow furrow drawn in the soil with a hoe or a finger, into which seed is dropped at its spacing and then covered."),
        Term(term: "Transplant", means: "A plant started elsewhere and set out in its final bed; also the act of setting it out. Days to maturity for a transplanted crop count from this day."),
        Term(term: "Hardening off", means: "The week in which seedlings raised indoors are put outside for longer each day, and brought in at night, before they are planted out for good."),
        Term(term: "Cold frame", means: "A low box with a glass or plastic lid, set on the ground, that traps the sun's warmth. Used to harden off trays and to carry salads through the cold months."),
        Term(term: "Cloche", means: "A cover set over a plant or a row, glass or plastic, to hold off frost and hasten growth. A row cover or fleece does the same job more cheaply."),
        Term(term: "Days to maturity", means: "The days from sowing, or from transplanting for started crops, to the first harvest under fair conditions. Given as a range because weather moves it."),
        Term(term: "Harvest window", means: "The span of days after maturity in which a crop is at its best. A week for radish, a fortnight for lettuce, months for chard. Pull inside it."),
        Term(term: "Bolting", means: "Running to flower and seed before the crop was ready, usually from heat, long days or a cold check. Lettuce, spinach and cilantro do it fastest."),
        Term(term: "Succession sowing", means: "Sowing a short row every two or three weeks so that a quick crop comes in steadily instead of all at once. Radish, lettuce, beans and carrots."),
        Term(term: "Square-foot spacing", means: "Planting by count per twelve-inch square instead of by row: one at twelve inches, four at six, nine at four, sixteen at three.")
    ]
}

enum GlossaryC {
    static let list: [Term] = [
        Term(term: "Thinning", means: "Pulling or snipping surplus seedlings so that those left stand at the crop's spacing. Done at the two-true-leaf stage, and in the evening for carrots."),
        Term(term: "Crop rotation", means: "Moving each plant family to a different bed each season so that the pests and soil diseases it leaves behind do not meet it again."),
        Term(term: "Family", means: "A botanical grouping of crops that share diseases and pests. The almanac uses ten: brassica, allium, nightshade, cucurbit, legume, umbel, aster, amaranth, grass and mint."),
        Term(term: "Brassica", means: "The cabbage family: cabbage, kale, broccoli, cauliflower, kohlrabi, radish, turnip, arugula and their kin. Hungry, hardy, and prone to clubroot."),
        Term(term: "Allium", means: "The onion family: onion, garlic, leek, scallion and chives. Light feeders that hate weed competition and resent standing beside peas and beans."),
        Term(term: "Nightshade", means: "Tomato, potato, pepper, eggplant and tomatillo. All killed by frost, all sharing blight, and never following one another in a bed."),
        Term(term: "Cucurbit", means: "Squash, pumpkin, cucumber, melon and watermelon: sprawling, thirsty vines sown only into warm soil."),
        Term(term: "Legume", means: "Peas and beans, which fix nitrogen in root nodules and leave the bed richer. The classic crop to grow before the brassicas."),
        Term(term: "Umbel", means: "The carrot family: carrot, parsnip, celery, parsley, dill, fennel and cilantro, named for their umbrella of tiny flowers. Direct-sown and slow to germinate."),
        Term(term: "Companion", means: "A crop that helps its neighbour, by drawing beneficial insects, fixing nitrogen, shading, or simply by asking for different things from the soil.")
    ]
}

enum GlossaryD {
    static let list: [Term] = [
        Term(term: "Antagonist", means: "A crop that harms its neighbour. Fennel stunts most plants; alliums slow peas and beans; sunflowers check potatoes and pole beans."),
        Term(term: "Allelopathy", means: "The release by a plant's roots or leaves of compounds that check the growth of other plants. Fennel, sunflower and walnut are the garden's examples."),
        Term(term: "Insectary plant", means: "A flowering plant grown to feed hoverflies, lacewings and parasitic wasps, whose larvae eat pests. Calendula, marigold, dill and nasturtium."),
        Term(term: "Trap crop", means: "A plant that pests prefer to the crop, grown beside it to draw them off. Nasturtium beside the cabbages."),
        Term(term: "Green manure", means: "A crop grown to be dug back into the soil rather than eaten: rye, vetch, clover, field peas. Sown in autumn, turned in before spring."),
        Term(term: "Cover crop", means: "Any crop grown to protect and feed bare soil, usually over winter. Most cover crops are turned in as green manure."),
        Term(term: "Mulch", means: "A layer of straw, leaves, clippings or compost laid over the soil to hold water, even the temperature and smother weeds."),
        Term(term: "Blossom-end rot", means: "A black, leathery patch at the base of a tomato, pepper or squash fruit, caused by calcium failing to reach the fruit when water is uneven. Steady water cures it."),
        Term(term: "Clubroot", means: "A soil fungus that swells and rots brassica roots and persists for seven years. Lime the bed, keep the family moving, and never compost an infected root."),
        Term(term: "Blight", means: "A fungus-like disease of tomatoes and potatoes that arrives in warm wet weather as dark blotches and can destroy a crop in days. Infected plants come out at once.")
    ]
}

enum GlossaryE {
    static let list: [Term] = [
        Term(term: "Carrot fly", means: "A small fly whose maggots tunnel carrot and parsnip roots. It finds the crop by the smell of bruised leaves, so thin in the evening and cover with mesh."),
        Term(term: "Seed tray", means: "A shallow tray of cells or a flat of compost in which seed is started indoors. In the plot, the tray holds a crop until its planting-out window opens."),
        Term(term: "Sets", means: "Small onion bulbs planted a month before the last frost to grow into full bulbs. Faster and surer than onion from seed, but more likely to bolt if planted large."),
        Term(term: "Slips", means: "Rooted shoots sprouted from a sweet potato tuber and set out into warm soil after the last frost. Sweet potatoes are grown from slips, never from seed."),
        Term(term: "Crown", means: "The perennial rootstock of rhubarb, asparagus or strawberry, planted in spring with the bud at soil level. Nothing is cut in the first year while the crown builds.")
    ]
}
