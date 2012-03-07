# Greenwich Proofer

Proofer is a small application for checking the relative correctness of translations you receive. Translations may be done by volunteers and there is no guarantee of their correctness. Publishing an internationalized version of your application where you have no idea what the text is saying is scary and potentially dangerous.

After editing translations for an app, Greenwich packages these translations into a `.tbz` file. Open this file with the proofer and select Proof to receive translations of all of the files in the archive. The output will be a directory with an identical structure to the contents of the `.tbz`. However, all of the `.strings` files will have an additional line for each translation.

Here's an example:

The original `.strings` file produced by Greenwich looks like this:

	/* No comment provided by engineer. */
	"quarter" = "Quartal";

	/* No comment provided by engineer. */
	"quarters" = "Quartale";

	/* No comment provided by engineer. */
	"this month" = "dieser Monat";

	/* No comment provided by engineer. */
	"this quarter" = "dieses Quartal";

After passing through the Proofer the corresponding output file would have this format:

	/* Translation = Original = Proofed */
	"Quartal" = "quarter" = "Quarter"
	"Quartale" = "quarters" = "Quarters"
	"dieser Monat" = "this month" = "This month"
	"dieses Quartal" = "this quarter" = "this quarter"

The translation provided by the translator is on the left side, followed by the original word in the application that the translator is translating from, and then the translation provided by Microsoft's Translate API at the end. The original and proofed phrases are next to each other to enable ease of comparison.

Proofer uses Microsoft's translation API to translate the text. Here are the steps for obtaining a Microsoft Translation Access Token:

  1. If you don't have a Windows Live account, you'll have to make one at live.com.
  1. Go to the [Azure Marketplace](https://datamarket.azure.com/dataset/1899a118-d202-492c-aa16-ba21c33c06cb) and sign up for Microsoft Translator. The free plan will let you translate 2,000,000 characters per month. Click Sign Up for the plan you'd like, enter your information, and accept the terms of use.
  1. [Register an application](https://datamarket.azure.com/developer/applications/) so you can begin using the translation service. 
    - The Client ID is an arbitrary name for your application that you choose.
    - The Name is an arbitrary name of what you'd like to call your application.
    - I'm not sure what the Redirect URI is for.
  1. Click "Edit" on the application to view your information again. You'll need the client ID and the client secret.
  1. Open the proofer and enter the Client ID and Client Secret from the Azure application edit screen.
