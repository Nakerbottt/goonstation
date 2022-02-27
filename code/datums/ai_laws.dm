//This class is now a handler for all global AI law rack functions
//if you want to get laws and details about a specific rack, call the functions on that rack
//if you want to get laws and details about all racks - this is where you'd look
//this also keeps track of the default rack

/datum/ai_rack_manager

	var/first_registered = FALSE
	var/obj/machinery/lawrack/default_ai_rack = null
	var/list/obj/machinery/lawrack/registered_racks = new()

	New() //got to do it this way because ticker is init after map
		. = ..()
		for_by_tcl(R, /obj/machinery/lawrack)
			src.register_new_rack(R)
		for (var/mob/living/silicon/S in mobs)
			S.law_rack_connection = src.default_ai_rack


	proc/register_new_rack(var/obj/machinery/lawrack/new_rack)
		if(isnull(src.default_ai_rack))
			src.default_ai_rack = new_rack

			#ifdef LAW_RACK_EASY_MODE
			for (var/mob/living/silicon/S in mobs)
				if(!S.emagged && S.law_rack_connection == null)
					S.law_rack_connection = src.default_ai_rack
					S.show_laws()
			#endif

		if(!src.first_registered)
			src.default_ai_rack.SetLaw(new /obj/item/aiModule/asimov1,1,true,true)
			src.default_ai_rack.SetLaw(new /obj/item/aiModule/asimov2,2,true,true)
			src.default_ai_rack.SetLaw(new /obj/item/aiModule/asimov3,3,true,true)
			src.first_registered = TRUE
		src.registered_racks += new_rack

	proc/unregister_rack(var/obj/machinery/lawrack/dead_rack)
		if(src.default_ai_rack == dead_rack)
			//ruhoh
			src.default_ai_rack = null
		//remove from list
		src.registered_racks -= dead_rack

		//find all connected borgs and remove their connection too
		for (var/mob/living/silicon/R in mobs)
			if (isghostdrone(R))
				continue
			if(R.law_rack_connection == dead_rack)
				R.law_rack_connection = null
				R << sound('sound/misc/lawnotify.ogg', volume=100, wait=0)
				R.show_text("<h3>ERROR: Lost connection to law rack. No laws detected!</h3>", "red")

		for (var/mob/living/intangible/aieye/E in mobs)
			if(E.mainframe?.law_rack_connection == dead_rack)
				E.mainframe.law_rack_connection = null
				E << sound('sound/misc/lawnotify.ogg', volume=100, wait=0)



/* General ai_law functions */
	proc/format_for_irc()
		var/list/laws = list()
		for(var/obj/machinery/lawrack/R in src.registered_racks)
			laws += R.format_for_irc()
		return laws


	proc/format_for_logs(var/glue = "<br>")
		var/list/laws = list()
		var/area/A
		for(var/obj/machinery/lawrack/R in src.registered_racks)
			A = get_area(R.loc)

			laws += "Laws for [R] at [A ? A.name : "...er somewhere?"]:<br>" + R.format_for_logs(glue) +"<br>--------------<br>"
		return jointext(laws, glue)
