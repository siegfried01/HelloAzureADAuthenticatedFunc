using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System.Security.Claims;
using System.Text;

namespace HelloAzureADAuthenticatedFunc
{
    public static class Hello
    {
        [FunctionName("Hello")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
            ClaimsPrincipal claimsPrincipals,
            ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");
            var sb = new StringBuilder();
            var identity = req.HttpContext?.User?.Identity as ClaimsIdentity;
            sb.AppendLine($"<br/>IsAuthenticated: \"{identity?.IsAuthenticated}\"");
            sb.AppendLine($"<br/>Identity name: \"{identity?.Name}\"");
            sb.AppendLine($"<br/>AuthenticationType: \"{identity?.AuthenticationType}\"");
            var count = 0;
            foreach (var claim in identity?.Claims)
            {
                count++;
                if (count == 1)
                    sb.AppendLine($"<ol>");
                sb.AppendLine($"<li>Identity Claim: {claim.Type} : {claim.Value}</li>");
            }
            foreach (var claim in req.HttpContext?.User?.Claims)
            {
                count++;
                if (count == 1)
                    sb.AppendLine($"<ol>");
                sb.AppendLine($"<li>Claim: {claim.Type} : {claim.Value}</li>");
            }
            foreach (var claim in req.HttpContext?.User?.Identities)
            {
                count++;
                if (count == 1)
                    sb.AppendLine($"<ol>");
                sb.AppendLine($"<li>Identities: {claim} </li>");
            }

            foreach (var claim in claimsPrincipals.Claims)
            {
                count++;
                if (count == 1)
                    sb.AppendLine($"<ol>");
                sb.AppendLine($"<li>ClaimPrincipal.claims: {claim.Type} : {claim.Value}</li>");
            }

            if (count == 0) sb.AppendLine("<br/> No identity claims found");
            else sb.AppendLine("</ol>");
            try
            {
                // https://copyprogramming.com/howto/csharp-asp-net-core-get-token-from-header
                //string auth1 = $"{req.Headers.Authorization}";
                string auth = req.Headers["Authorization"];
                auth = auth.Replace("Bearer", "").Trim(' ', '\n', '\r');
                sb.AppendLine($"<br/> req.Headers.Authorization=Bearer \"{auth}\"");
                /*
                var handler = new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler();
                var decodedResult = "";
                try
                {
                    var jwtSecurityToken = handler.ReadJwtToken(auth);
                    decodedResult = jwtSecurityToken.ToString();
                }
                catch (Exception ex)
                {
                    decodedResult = ex.ToString();
                }
                sb.AppendLine($"<br/> <b>decoded</b>={decodedResult}");
                */
            }
            catch (System.Collections.Generic.KeyNotFoundException ex)
            {
                sb.AppendLine("<br/> No authorization header found");
            }
            return (ActionResult)new OkObjectResult($"Hello, time and date are {DateTime.Now.ToString()}. (Built at Mon Apr 24 20:57:36 2023) {sb.ToString()}");
        }
    }
}
